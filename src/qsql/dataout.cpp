#include "dataout.h"

DataOut::DataOut(QCoreApplication &a, QObject *parent):QObject{parent},connection{this}{
    this->makeArgs(a);
}


/*
--quiet --hostname=localhost --username=services --password=services --port=5432 -database=services -format= -c="select*from pg_catalog.pg_tables"
*/

void DataOut::makeArgs(QCoreApplication &a)
{
    auto getArg=[this](QStringList keyNames, const QVariant &defaultValue={})
    {
        for(auto &arg: keyNames){
            QStringList keys={arg,"-"+arg,"--"+arg,"/"+arg};
            for(auto&key:keys){
                if(arguments.contains(key)){
                    auto v=arguments.value(key).toString().trimmed();
                    if(!v.isEmpty())
                        return QVariant(v);
                }
            }
        }
        return defaultValue;
    };

    QStringList argsIn=a.arguments();
    for(auto&arg:argsIn){
        if(!arg.startsWith("--"))
            continue;
        auto values=arg.split("=");
        auto key=values.takeFirst();
        auto value=values.join("=");
        arguments.insert(key,value);
    }
    auto&connection=this->connection;
    connection.driverName=getArg({"d","drivername","driver"},"QPSQL").toString();
    connection.hostName=getArg({"h","hostname","host"},"localhost").toString();
    connection.userName=getArg({"u","username","user"},"postgres").toString();
    connection.password=getArg({"p","password","pass","pwd"},"postgres").toString();
    connection.database=getArg({"d","database","db"},"postgres").toString();
    connection.port=getArg({"p","port"},"5432").toInt();

    this->debug=this->arguments.contains("--debug");
    this->output=getArg({"o","output"}).toString();
    this->quiet=getArg({"q","quiet"},true).toBool();
    this->command=getArg({"c","command","cmd"}).toString();
    this->format(getArg({"f","format"},QT_STRINGIFY(NONE)).toString());
}

bool DataOut::execute()
{
    this->log("exec started");
    auto &connection=this->connection;
    if(this->command.trimmed().isEmpty())
        return true;

    QString command;
    if(QFile::exists(this->command)){
        QFile file(this->command);
        this->log(QString("load file: %1").arg(file.fileName()));
        if(!file.open(QFile::ReadOnly)){
            qCritical()<<file.errorString();
            return false;
        }
        command=file.readAll();
        file.close();
    }
    //    else if(QDir(connection.command).exists()){
    //        QDir dir(connection.command);
    //    }
    else{
        command=this->command.trimmed();
    }

    if(command.isEmpty()){
        this->log("command is empty");
        return false;
    }

    this->log(QString("command : %1").arg(command));


    auto db=QSqlDatabase::addDatabase(connection.driverName,QUuid::createUuid().toString());
    db.setHostName(connection.hostName);
    db.setUserName(connection.userName);
    db.setPassword(connection.password);
    db.setPort(connection.port);
    db.setDatabaseName(connection.database);
    this->log(QString("database connecting: driver: %1, hostName: %2").arg(db.driverName(),db.hostName()));
    if(!db.open()){
        qCritical()<<db.lastError();
        return false;
    }
    if(db.driverName()=="QPSQL"){
        db.exec("set client_min_messages to WARNING;");
        db.exec("drop schema if exists agt_v1 cascade;");
    }
    this->log("database connected");

    QSqlQuery query(db);

    this->log("command executing");
    if(!query.exec(command)){
        qCritical()<<query.lastError();
        return false;
    }
    this->log("command executed");
    read(query);
    query.clear();
    query.finish();
    this->log("exec finished");
    return true;
}

DataOut::Format DataOut::format(){
    return _format;
}

void DataOut::format(const QString &format){
    auto eFormat=QMetaEnum::fromType<Format>();
    auto v=eFormat.keyToValue(format.toUpper().toUtf8());
    this->_format=Format(v);
}

void DataOut::read(QSqlQuery &query){
    this->log("read result set: start");
    this->fields.clear();
    while(query.next()){
        if(fields.isEmpty()){
            auto record=query.record();
            for(int index=0;index<=record.count();index++){
                auto field=record.field(index);
                this->fields.append(Field(index,field));
            }
            this->printHeader();
        }
        if(this->format()==JSON){
            QVariantHash row;
            for(auto &field: fields){
                if(field.visible)
                    row.insert(field.name, field.value());
            }
            this->printRow(row);
        }
        else{
            QVariantList row;
            for(auto &field: fields)
                row.append(field.value());
            this->printRow(row);
        }
    }
    query.finish();
    query.clear();
    this->printSummary();
    this->log("read result set: finished");
}

void DataOut::printHeader()
{
    if(this->format()==JSON){
        print("[");
        return;
    }
}

void DataOut::printSummary(){
    if(this->format()==TEXT)
        return;
    if(this->format()==JSON){
        if(!this->lastRow.isEmpty())
            this->print(this->lastRow);
        print("]");
        return;
    }
}

void DataOut::printRow(const QVariant &row){

    if(this->format()==TEXT){
        return;
    }

    if(this->format()==JSON){
        if(!lastRow.isEmpty())
            print(lastRow+",");
        this->lastRow=QJsonDocument::fromVariant(row).toJson(QJsonDocument::Compact);
        return;
    }
}

void DataOut::print(const QByteArray &line){
    printf("%s\n",line.toStdString().data());
}

void DataOut::log(const QString &message)
{
    if(this->debug)
        printf("qsql: %s\n",message.toStdString().data());
}
