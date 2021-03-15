/****************************************************************************
**
** Copyright (c) 2014 - 2019 Jolla Ltd.
** Copyright (c) 2019 - 2021 Open Mobile Platform LLC.
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Browser 1.0
import org.nemomobile.configuration 1.0
import "." as Browser
import "../../shared" as Shared

Private.TabView {
    id: tabs

    property bool portrait
    property bool privateMode
    property var tabModel

    signal hide
    signal enterNewTabUrl
    signal activateTab(int index)
    signal closeTab(int index)
    signal closeAll
    signal closeAllCanceled
    signal closeAllPending

    anchors.fill: parent

    header: Private.TabBar {
        id: header
        model: headerModel
        Shared.Background {
            anchors.fill: parent
            z: -1
        }
    }

    model: [ persistentTabView, privateTabView ]

    onCurrentIndexChanged: {
        // TODO: Add remorsePopup
        // if (remorsePopup) {
        //     remorsePopup.trigger()
        // }
        privateMode = currentIndex !== 0
    }
    Component.onCompleted: {
        persistentIcon.updateGrubImage()
        privateIcon.updateGrubImage()
        currentIndex = privateMode
    }

    PrivateModeTexture {
        z: -1
        visible: opacity > 0.0
        opacity: privateMode ? 1.0 : 0.0

        Behavior on opacity { FadeAnimation {} }
    }

    Component {
        id: persistentTabView

        Private.TabItem {
            TabGridView {
                id: _persistentTabView
                privateMode: false
                portrait: tabs.portrait
                model: tabs.tabModel

                onHide: tabs.hide()
                onEnterNewTabUrl: tabs.enterNewTabUrl()
                onActivateTab: tabs.activateTab(index)
                onCloseTab: tabs.closeTab(index)
                onCloseAll: tabs.closeAll()
                onCloseAllCanceled: tabs.closeAllCanceled()
                onCloseAllPending: tabs.closeAllPending()
            }
        }
    }
    Component {
        id: privateTabView
        Private.TabItem {
            allowDeletion: false
            TabGridView {
                id: _privateTabView
                privateMode: true
                portrait: tabs.portrait
                model: tabs.tabModel

                onHide: tabs.hide()
                onEnterNewTabUrl: tabs.enterNewTabUrl()
                onActivateTab: tabs.activateTab(index)
                onCloseTab: tabs.closeTab(index)
                onCloseAll: tabs.closeAll()
                onCloseAllCanceled: tabs.closeAllCanceled()
                onCloseAllPending: tabs.closeAllPending()
            }
        }
    }

    ListModel {
        id: headerModel

        ListElement {
            iconSource: ""
        }
        ListElement {
            iconSource: ""
        }
    }

    function _updateHeaderModel() {
        headerModel.set(0, { "iconSource": persistentIcon.grabIcon })
        headerModel.set(1, { "iconSource": privateIcon.grabIcon })
    }

    Connections {
        target: tabModel
        onCountChanged: {
            persistentIcon.updateGrubImage()
            privateIcon.updateGrubImage()
        }
    }

    children: [
        Image {
            id: persistentIcon
            property string grabIcon

            source: "image://theme/icon-m-tabs"
            Label {
                anchors.centerIn: parent
                text: webView.persistentTabModel.count
                font.pixelSize: Theme.fontSizeExtraSmall
                font.bold: true
            }

            function updateGrubImage() {
                persistentIcon.grabToImage(function(result) {
                    grabIcon = result.url
                    _updateHeaderModel()
                });
            }
        },

        Image {
            id: privateIcon
            property string grabIcon

            source: "image://theme/icon-m-incognito"
            Label {
                anchors.centerIn: parent
                text: webView.privateTabModel.count
                font.pixelSize: Theme.fontSizeExtraSmall
                font.bold: true
            }

            function updateGrubImage() {
                privateIcon.grabToImage(function(result) {
                    grabIcon = result.url
                    _updateHeaderModel()
                });
            }
        }
    ]
}
