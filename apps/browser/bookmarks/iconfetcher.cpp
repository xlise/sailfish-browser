/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "iconfetcher.h"
#include "opensearchconfigs.h"

#include <webengine.h>

#include <QImage>
#include <QUrl>
#include <QDir>
#include <QFile>

IconFetcher::IconFetcher(QObject *parent)
    : QObject(parent)
    , m_status(Null)
    , m_minimumIconSize(64) // Initial value that matches theme iconSizeMedium.
    , m_hasAcceptedTouchIcon(false)
    , m_url(NULL)
{
}

void IconFetcher::fetch(const QString &iconUrl)
{
    updateAcceptedTouchIcon(false);
    m_url = new QUrl(iconUrl);
    QString path = m_url->path();
    updateStatus(Fetching);
    if (path.endsWith(".ico") || iconUrl.isEmpty()) {
        m_data = defaultIcon();
        updateStatus(Ready);
        emit dataChanged();
    } else {
        QNetworkRequest request(*m_url);
        QNetworkReply *reply = m_networkAccessManager.get(request);
        connect(reply, &QNetworkReply::finished, this, &IconFetcher::dataReady);
        // qOverload(T functionPointer) would be handy to resolve right error method but it is introduced only
        // in Qt5.7. QNetWorkReply has signal error(QNetworkReply::NetworkError) and method error().
        // connect(reply, qOverload<QNetworkReply::NetworkError>(&QNetworkReply::error), this, IconFetcher::error);
        connect(reply, SIGNAL(error(QNetworkReply::NetworkError)), this, SLOT(error(QNetworkReply::NetworkError)));
    }
}

IconFetcher::Status IconFetcher::status() const
{
    return m_status;
}

QString IconFetcher::data() const
{
    return m_data;
}

QString IconFetcher::defaultIcon() const
{
    return DEFAULT_DESKTOP_BOOKMARK_ICON;
}

bool IconFetcher::hasAcceptedTouchIcon()
{
    return m_hasAcceptedTouchIcon;
}

void IconFetcher::dataReady()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (reply) {
        m_networkData = reply->readAll();
        QImage image;
        image.loadFromData(m_networkData);
        if (image.width() < m_minimumIconSize || image.height() < m_minimumIconSize) {
            m_data = defaultIcon();
        } else {
            m_data = QString(BASE64_IMAGE).arg(QString(m_networkData.toBase64()));
        }
        reply->deleteLater();

        updateAcceptedTouchIcon(true);
        updateStatus(Ready);
        emit dataChanged();
    } else {
        m_data = defaultIcon();
        updateStatus(Ready);
        emit dataChanged();
    }
}

void IconFetcher::error(QNetworkReply::NetworkError)
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (reply) {
        reply->deleteLater();
    }

    m_data = defaultIcon();
    updateStatus(Error);
    emit dataChanged();
}

void IconFetcher::updateStatus(IconFetcher::Status status)
{
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
    }
}

void IconFetcher::updateAcceptedTouchIcon(bool acceptedTouchIcon)
{
    if (m_hasAcceptedTouchIcon != acceptedTouchIcon) {
        m_hasAcceptedTouchIcon = acceptedTouchIcon;
        emit hasAcceptedTouchIconChanged();
    }
}

bool IconFetcher::saveAsSearchEngine()
{
    if (!m_url || m_networkData.isEmpty())
        return false;

    bool rv = false;
    QUrl url = QUrl::fromLocalFile(OpenSearchConfigs::getOpenSearchConfigPath() + m_url->host() + ".xml");
    QDir dir;
    if (dir.mkpath(url.toString(QUrl::RemoveScheme | QUrl::RemoveFilename))) {
        QFile file(url.path());
        if (file.open(QIODevice::WriteOnly)) {
            if (file.write(m_networkData) > 0) {
                rv = true;
            }
            file.close();

            if (rv) {
                // Inform WebEngine there's a new search xml
                QVariantMap loadsearch;
                loadsearch.insert(QLatin1String("msg"), QVariant(QLatin1String("loadxml")));
                loadsearch.insert(QLatin1String("uri"), QVariant(url.toString()));
                loadsearch.insert(QLatin1String("confirm"), QVariant(false));
                SailfishOS::WebEngine::instance()->notifyObservers(QLatin1String("embedui:search"), QVariant(loadsearch));
            }
        }
    }

    return rv;
}
