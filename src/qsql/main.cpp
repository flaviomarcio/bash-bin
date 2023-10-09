#include <QCoreApplication>
#include "dataout.h"

/*
--quiet --hostname=localhost --username=services --password=services --port=5432 -database=services -format=json -c="select*from pg_catalog.pg_tables"
*/


int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);
    DataOut dataOut(a);
    return (!dataOut.execute())
        ?QProcess::ExitStatus::CrashExit
        :QProcess::ExitStatus::NormalExit;



//    return a.exec();
}
