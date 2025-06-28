# **FieldX FSM – Mobile CRM για Field Service Management**

Το **FieldX FSM** είναι η mobile επέκταση του **FieldX CRM**, αναπτυγμένη από την **Apparat** με χρήση του **Flutter**. Σχεδιασμένη ειδικά για **Field Service Management (FSM)**, η εφαρμογή δίνει στους τεχνικούς πεδίου ένα πλήρες εργαλείο διαχείρισης εργασιών, πελατών και αυτοψιών, με υποστήριξη **offline-first λειτουργικότητας**.

---

## **:pushpin: Custom Flutter Dependencies που Χρησιμοποιούνται**

### **:open_file_folder: Data Storage & Persistence**
- **cloud_firestore** – Real-time βάση δεδομένων με Firebase.
- **hive / hive_flutter / hive_generator** – Lightweight NoSQL local database.
- **shared_preferences** – Τοπική αποθήκευση απλών ρυθμίσεων.
- **flutter_secure_storage** – Ασφαλής κρυπτογραφημένη αποθήκευση δεδομένων.

### **:globe_with_meridians: Networking & API Communication**
- **http / dio** – Επικοινωνία με REST APIs (GET, POST, PUT κ.λπ.).
- **web_socket_channel** – Real-time WebSocket επικοινωνία.
- **connectivity_plus** – Έλεγχος σύνδεσης στο Internet.

### **:round_pushpin: Location Services & Maps**
- **geolocator** – Γεωεντοπισμός και παρακολούθηση θέσης.
- **flutter_osm_plugin** – Ενσωμάτωση OpenStreetMap με offline δυνατότητες.

### **:pencil: File Handling & Signatures**
- **image_picker** – Επιλογή εικόνων από κάμερα ή gallery.
- **file_picker** – Επιλογή αρχείων από τη συσκευή.
- **signature** – Λήψη και αποθήκευση ψηφιακών υπογραφών.
- **mime** – Αναγνώριση τύπων αρχείων για file uploads.

### **:bell: Notifications**
- **awesome_notifications** – Push Notifications με custom actions.

### **:art: UI / UX Components**
- **google_fonts** – Ενσωμάτωση Google Fonts.
- **material_design_icons_flutter** – Υποστήριξη Material Design Icons.
- **flutter_html** – Απόδοση HTML περιεχομένου.
- **fl_chart** – Γραφήματα και Charts.
- **table_calendar** – Calendar View.
- **intl** – Διαχείριση ημερομηνιών, ωρών και format.
- **provider** – State management.

### **:page_facing_up: PDF, Printing & Excel Reports**
- **pdf / printing** – Δημιουργία και εκτύπωση PDF.
- **excel** – Εξαγωγή δεδομένων σε Excel μορφή.

### **:mobile_phone: Device Info & App Metadata**
- **device_info_plus / package_info_plus** – Στοιχεία συσκευής και app versioning.
- **permission_handler** – Διαχείριση δικαιωμάτων χρήστη.
- **flutter_cache_manager** – Αποθήκευση και διαχείριση cache.

### **:key: Authentication**
- **google_sign_in** – Google OAuth Login.

### **:tools: Utility Libraries**
- **mobile_scanner** – Barcode / QR code scanning.
- **flutter_dotenv** – Φόρτωση περιβαλλοντικών μεταβλητών από .env αρχεία.
- **json_annotation / json_serializable / build_runner** – JSON serialization / code generation.
- **weather** – Πρόσβαση σε Weather APIs για εμφάνιση καιρού.

---

## **:pushpin: App Version**
**FieldX FSM v3.3.3+12**

## **:pushpin: Flutter SDK**
**Flutter SDK 3.6.1**

## **:pushpin: Platforms**
- :white_check_mark: **Android**
- :o: **iOS (not targeted currently)**

---

## **:pushpin: Summary**

Το **FieldX FSM** αποτελεί ένα **offline-first, real-time enabled**, πλήρως επεκτάσιμο εργαλείο για **Field Technicians**, με **εργασίες**, **αυτοψίες**, **γεωγραφικά δεδομένα**, **ειδοποιήσεις**, **έγγραφα PDF**, **Excel exports** και πολλά ακόμα.

Ιδανικό για κάθε επιχείρηση που δραστηριοποιείται στον χώρο του **Field Service**.

---

**Powered by Apparat | Built with Flutter**
