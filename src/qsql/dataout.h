#pragma once

#include <QCoreApplication>
#include <QVariantMap>
#include <QStringList>
#include <QSqlDatabase>
#include <QUuid>
#include <QSqlError>
#include <QSqlQuery>
#include <QFile>
#include <QDir>
#include <QProcess>
#include <QJsonDocument>
#include <QSqlRecord>
#include <QSqlField>
#include <QMetaEnum>


class Connection:public QObject{
public:
    QString driverName;
    QString hostName;
    QString userName;
    QString password;
    QString database;
    int port;
    explicit Connection(QObject *parent=nullptr):QObject{parent}{
    }

};

struct Field{
public:
    int index;
    QString name;
    QSqlField f;
    int typeId;
    bool visible=false;
    explicit Field(int index,QSqlField field){
        this->index=index;
        this->f=field;
        this->name=field.name();
        this->typeId=field.typeID();
        this->visible=!this->name.isEmpty();

    }
    QVariant value(){
        return f.value();
    }
};


class DataOut:public QObject{
    Q_OBJECT
public:
    enum Format{
        NONE,JSON,TEXT
    };
    bool debug=false;
    QByteArray lastRow;
    Connection connection;
    QSqlRecord record;
    QVector<Field> fields;
    bool printed=false;

    QString command;
    QString output;
    bool quiet;

    QVariantHash arguments;

    Q_ENUM(Format)
    explicit DataOut(QCoreApplication&a,QObject *parent=nullptr);

    void makeArgs(QCoreApplication&a);

    bool execute();

    Format format();
    void format(const QString &format);

    void read(QSqlQuery &query);

    void printHeader();
    void printSummary();
    void printRow(const QVariant &row);
    void print(const QByteArray &line);
    void log(const QString &message);
private:
    Format _format;
};
