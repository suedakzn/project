from django import db
from flask_cors import CORS
from PIL import Image
import pymysql
from flask import Flask, jsonify, request
import os
import json
import cv2
import numpy as np
import uuid
import torch
from torchvision import transforms
from yolov5 import YOLOv5
import jwt

# Flask uygulaması
app = Flask(__name__)
CORS(app)  # Tüm endpointlere CORS açıldı (isteğe göre daraltılabilir)

# Veritabanı bağlantı ayarları
DATABASE_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "S!k184445",
    "database": "userdata",
    "cursorclass": pymysql.cursors.DictCursor
}

# YOLOv5 modeli yolu
model_path = "C:\\Users\\sueda\\Desktop\\final_year\\backend\\models\\best.pt"
model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path, force_reload=True)

# Upload klasörü
UPLOAD_FOLDER = './uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


# Veritabanı bağlantısı oluştur
def create_connection():
    try:
        connection = pymysql.connect(**DATABASE_CONFIG)
        print("Database bağlantısı başarılı.")
        return connection
    except Exception as e:
        print(f"Database bağlantısı başarısız: {e}")
        return None


# Kullanıcı ekleme endpointi
@app.route("/users", methods=["POST"])
def add_user():
    try:
        data = request.json
        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({"error": "All fields are required"}), 400

        connection = create_connection()
        if not connection:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
            if cursor.fetchone():
                return jsonify({"error": "This email is already registered"}), 409

            cursor.execute(
                "INSERT INTO users (email, password) VALUES (%s, %s)",
                (email, password),
            )
            connection.commit()
            user_id = cursor.lastrowid

        return jsonify({"message": "User added successfully!", "user_id": user_id}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if connection:
            connection.close()


# Parent bilgisi ekleme endpointi
@app.route("/parent", methods=["POST"])
def add_parent_info():
    try:
        data = request.json
        user_id = data.get("user_id")
        first_name = data.get("first_name")
        last_name = data.get("last_name")
        birth_date = data.get("birth_date")
        country = data.get("country")
        phone_number = data.get("phone_number")
        gender = data.get("gender")

        if not all([user_id, first_name, last_name, birth_date, country, phone_number, gender]):
            return jsonify({"error": "All fields are required!"}), 400

        connection = create_connection()
        if not connection:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO parent_info (user_id, first_name, last_name, birth_date, country, phone_number, gender)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (user_id, first_name, last_name, birth_date, country, phone_number, gender),
            )
            connection.commit()

        return jsonify({"message": "Parent info added successfully!"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if connection:
            connection.close()


# Çocuk ekleme endpointi
@app.route('/add_child', methods=['POST'])
def add_child():
    try:
        data = request.json
        print(f"Received data: {data}")

        parent_id = data.get('user_id')
        child_name = data.get('name')
        child_age = data.get('age')
        child_gender = data.get('gender')
        child_image = data.get('icon')  # İkon bilgisi child_image olarak alınacak

        if not all([parent_id, child_name, child_age, child_gender, child_image]):
            return jsonify({"error": "All fields are required!"}), 400

        connection = create_connection()
        if connection is None:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            cursor.execute(
                "INSERT INTO children (parent_id, child_name, child_age, child_gender, child_image) VALUES (%s, %s, %s, %s, %s)",
                (parent_id, child_name, child_age, child_gender, child_image)
            )
            connection.commit()

        return jsonify({"message": "Child added successfully!"}), 201

    except Exception as e:
        print(f"Error occurred: {e}")
        return jsonify({"error": str(e)}), 500

    finally:
        if connection:
            connection.close()

# Giriş endpoint
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({"error": "Email and password are required!"}), 400

        connection = create_connection()
        if connection is None:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users WHERE LOWER(email) = LOWER(%s)", (email,))
            user = cursor.fetchone()

        if user and user['password'] == password:
            parent_id = user['id']

            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT id, child_name, child_age, child_gender
                    FROM children WHERE parent_id = %s
                """, (parent_id,))
                children = cursor.fetchall()

            return jsonify({
                "parent_id": parent_id,
                "children": children
            }), 200
        else:
            return jsonify({"error": "Invalid email or password"}), 401

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        if connection:
            connection.close()




# Parent ID'ye Göre Çocukları Getirme Endpoint
@app.route('/children/<int:parent_id>', methods=['GET'])
def get_children_by_parent(parent_id):
    try:
        connection = create_connection()
        if not connection:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            # parent_id'ye bağlı çocukları çekiyoruz
            cursor.execute(
                """
                SELECT id, child_name, child_age, child_gender, child_image
                FROM children 
                WHERE parent_id = %s
                """,
                (parent_id,)
            )
            children = cursor.fetchall()

        # Veritabanı bağlantısını manuel olarak kapatma
        connection.close()

        # Eğer çocuk bulunamazsa boş liste dönecek
        if not children:
            return jsonify({"message": "No children found", "children": []}), 200

        return jsonify({"children": children}), 200

    except pymysql.MySQLError as e:
        # MySQL hataları için özel mesaj
        return jsonify({"error": f"Database error: {str(e)}"}), 500

    except Exception as e:
        # Diğer hatalar için genel mesaj
        return jsonify({"error": f"Unexpected error: {str(e)}"}), 500


@app.route('/update_card_color', methods=['POST'])
def update_card_color():
    data = request.json
    child_id = data['child_id']
    card_color = data['card_color']
    query = "UPDATE children SET card_color = %s WHERE id = %s"
    cursor.execute(query, (card_color, child_id))
    db.commit()
    return jsonify({"message": "Card color updated successfully"}), 200


@app.route('/analyze_child_image', methods=['POST'])
def analyze_child_image():
    try:
        # Dosyanın varlığını kontrol et
        if 'file' not in request.files:
            return jsonify({"error": "No file part"}), 400
        
        file = request.files['file']
        file_path = os.path.join(UPLOAD_FOLDER, f"{uuid.uuid4()}_{file.filename}")
        
        # Dosyayı kaydet
        file.save(file_path)

        # Görüntüyü yükle
        img = cv2.imread(file_path)
        if img is None:
            return jsonify({"error": "Görsel yüklenemedi. Desteklenen bir format olduğundan emin olun."}), 400
        
        # Görseli PIL formatına çevir
        img_pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))

        # YOLOv5 modeline görseli besleyin ve tahmin yapın
        results = model(img_pil)  # Tahmin yap

        # Tahmin sonuçlarını al
        labels = results.names
        predictions = results.xywh[0].cpu().numpy()

        feedback = []
        for pred in predictions:
            x_center, y_center, width, height, confidence, class_id = pred
            class_name = labels[int(class_id)]

            # Tahmin edilen etiketi geri bildirime ekle
            feedback.append({
                "class": class_name,
                "confidence": float(confidence),
                "bounding_box": {
                    "x_center": float(x_center),
                    "y_center": float(y_center),
                    "width": float(width),
                    "height": float(height)
                }
            })

        # Eksik ve yanlış boncukları kontrol et
        missing_beads = [f for f in feedback if f['class'] == 'missing_bead']
        wrong_beads = [f for f in feedback if f['class'] == 'wrong_bead']

        # Dosyayı temizle
        if os.path.exists(file_path):
            os.remove(file_path)

        # Sonucu döndür
        return jsonify({
            "status": "success",
            "feedback": feedback,
            "missing_count": len(missing_beads),
            "wrong_count": len(wrong_beads)
        }), 200

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": f"Beklenmeyen bir hata oluştu: {e}"}), 500


@app.route('/profile', methods=['GET'])
def get_profile():
    # parent_id parametresi sorguda var mı kontrol edelim
    user_id_raw = request.args.get('user_id')
    if not user_id_raw:
        return jsonify({"error": "user_id is required"}), 400

    try:
        # Parametreyi temizleyip int'e çeviriyoruz
        final_user_id = int(user_id_raw.strip())
    except ValueError:
        return jsonify({"error": "parent_id must be an integer"}), 400

    app.logger.info(f"Fetching profile for parent_id: {final_user_id}")

    connection = None
    try:
        connection = create_connection()
        if not connection:
            app.logger.error("Database connection failed.")
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            app.logger.info("Executing SQL query for profile.")
            cursor.execute("""
                SELECT 
                    first_name, 
                    last_name, 
                    birth_date, 
                    country, 
                    phone_number, 
                    gender
                FROM parent_info
                WHERE parent_id = %s
            """, (final_user_id,))
            profile = cursor.fetchone()

        if not profile:
            app.logger.error(f"No profile found for parent_id: {final_user_id}")
            return jsonify({"error": "Profile not found"}), 404

        app.logger.info(f"Profile found: {profile}")
        return jsonify(profile), 200

    except Exception as e:
        app.logger.exception("Unexpected error occurred in get_profile:")
        return jsonify({"error": "Unexpected error occurred. Please try again later."}), 500

    finally:
        if connection:
            connection.close()

    
@app.route('/logout', methods=['POST'])
def logout():
    token = request.headers.get('Authorization')  # Token'i al
    if token:
        blacklisted_tokens.add(token)  # type: ignore # Kara listeye ekle
        return jsonify({"message": "Logged out successfully."}), 200
    return jsonify({"error": "Token is required."}), 400

# 1. Çocukların listelenmesi
@app.route('/parental_control/children/<int:parent_id>', methods=['GET'])
def get_parental_control_children(parent_id):
    try:
        connection = create_connection()
        if connection is None:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            cursor.execute("SELECT id, child_name, play_limit FROM children WHERE parent_id = %s", (parent_id,))
            children = cursor.fetchall()

        return jsonify({"children": children}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if connection:
            connection.close()

# 2. Çocuğun oyun süresi sınırını belirleme
@app.route('/parental_control/set_play_limit', methods=['POST'])
def set_play_limit():
    try:
        data = request.json
        child_id = data.get('child_id')
        play_limit = data.get('play_limit')  # dakika cinsinden

        if not all([child_id, play_limit]):
            return jsonify({"error": "Child ID and play limit are required!"}), 400

        connection = create_connection()
        if connection is None:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            cursor.execute("UPDATE children SET play_limit = %s WHERE id = %s", (play_limit, child_id))
            connection.commit()

        return jsonify({"message": "Play limit updated successfully!"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if connection:
            connection.close()

# 3. Çocuğun haftalık aktivitelerini getirme
@app.route('/parental_control/activity_report/<int:child_id>', methods=['GET'])
def get_activity_report(child_id):
    try:
        connection = create_connection()
        if connection is None:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT activity_date, activity_type, duration 
                FROM activity_logs 
                WHERE child_id = %s 
                  AND activity_date >= DATE_SUB(NOW(), INTERVAL 1 WEEK)
                ORDER BY activity_date DESC
                """,
                (child_id,)
            )
            activity_report = cursor.fetchall()

        return jsonify({"activity_report": activity_report}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if connection:
            connection.close()




# 4. Aktivite kaydetme (örn: oyun oynama süresi veya görsel yükleme)
@app.route('/parental_control/log_activity', methods=['POST'])
def log_activity():
    try:
        data = request.json
        child_id = data.get('child_id')
        activity_type = data.get('activity_type')  # Örn: 'game', 'upload'
        duration = data.get('duration')  # dakika cinsinden

        if not all([child_id, activity_type, duration]):
            return jsonify({"error": "Child ID, activity type, and duration are required!"}), 400

        connection = create_connection()
        if connection is None:
            return jsonify({"error": "Database connection failed"}), 500

        with connection.cursor() as cursor:
            cursor.execute(
                "INSERT INTO activity_logs (child_id, activity_type, duration) VALUES (%s, %s, %s)",
                (child_id, activity_type, duration)
            )
            connection.commit()

        return jsonify({"message": "Activity logged successfully!"}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if connection:
            connection.close()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000) 

