FROM mysql:8.0.32
RUN echo "[mysqld]" >> /etc/mysql/my.cnf
RUN echo "default-authentication-plugin=mysql_native_password" >> /etc/mysql/my.cnf
# ~230 Mo mesures pour performance_schema seul : trop cher sur un VPS a 1 Go, et rien ne le lit.
RUN echo "performance_schema=OFF" >> /etc/mysql/my.cnf
# Binlogs actifs par defaut en MySQL 8 et gardes 30 jours. Sans replication ils ne font que
# remplir le disque (655 Mo sur le VPS) : 3 jours suffisent pour un point-in-time recovery.
RUN echo "binlog_expire_logs_seconds=259200" >> /etc/mysql/my.cnf
