#!/bin/bash

# ==================================
# Nextcloud Backup-Skript
# Optimiert für Aufgabe 007.
# ==================================

# --- Einstellungen ---
# Verzeichnis, in dem die Backups gespeichert werden
BACKUP_DIR="/var/backups/nextcloud"

# Name der zu sichernden Datenbank
DB_NAME="nextcloud"

# Datumsformat (z.B.: 2025-10-30_0845)
DATE_FORMAT=$(date +"%Y-%m-%d_%H%M")

# Wie viele Tage sollen Backups aufbewahrt werden?
RETENTION_DAYS=14

# SkrptStart 
echo "--- Nextcloud Backup wird gestartet: $DATE_FORMAT ---"

# 1. Sicherstellen, dass das Backup-Verzeichnis existiert
mkdir -p $BACKUP_DIR

# 2. Webserver stoppen (Für Datenintegrität / Atomares Backup)
echo "Nginx wird gestoppt..."
systemctl stop nginx

# 3. Dateien sichern
# -C /var/www/ nextcloud: Dies speichert das 'nextcloud'-Verzeichnis 
# direkt, ohne die übergeordnete /var/www/ Struktur. Erleichtert die Wiederherstellung.
echo "Dateien werden gesichert..."
tar -zcpf "$BACKUP_DIR/nextcloud-files-$DATE_FORMAT.tar.gz" -C /var/www/ nextcloud

# 4. Datenbank sichern
echo "Datenbank wird gesichert..."
# Bei Debian/Ubuntu-Systemen verwendet 'debian.cnf' (von 'root' ausgeführt)
# eine sichere, passwortlose Methode für Cron-Jobs.
mysqldump --defaults-file=/etc/mysql/debian.cnf $DB_NAME | gzip > "$BACKUP_DIR/nextcloud-db-$DATE_FORMAT.sql.gz"

# 5. Webserver neustarten
echo "Nginx wird gestartet..."
systemctl start nginx

# 6. Alte Backups löschen (âlter als 14 Tage)
echo "Backups, die älter als $RETENTION_DAYS Tage sind, werden gelöscht..."
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -exec rm {} \;
find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -exec rm {} \;

echo "Backup abgeschlossen "
echo "=========================================="