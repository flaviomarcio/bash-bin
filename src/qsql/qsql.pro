TARGET = qsql
TEMPLATE = app

QT += core
QT += sql
QT -= gui
QT -= location
QT += network

CONFIG += silent
CONFIG += c++17
CONFIG += silent
CONFIG -=qtquickcompiler


SOURCES += \
    $$PWD/main.cpp \
    dataout.cpp

HEADERS += \
    dataout.h
