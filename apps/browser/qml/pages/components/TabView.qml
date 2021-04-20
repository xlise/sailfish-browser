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

Item {
    id: root

    property bool portrait
    property bool privateMode
    property var tabModel
    property alias scaledPortraitHeight: tabsToolBar.scaledPortraitHeight
    property alias scaledLandscapeHeight: tabsToolBar.scaledLandscapeHeight

    signal hide
    signal enterNewTabUrl
    signal activateTab(int index)
    signal closeTab(int index)
    signal closeAll
    signal closeAllCanceled
    signal closeAllPending

    property var _remorsePopup
    anchors.fill: parent

    Private.TabView {
        id: tabs

        anchors {
            fill: parent
            bottomMargin: tabsToolBar.height
        }

        header: Private.TabBar {
            id: header
            model: headerModel
            Rectangle {
                anchors.fill: parent
                z: -1
                color: Theme.colorScheme == Theme.LightOnDark ? "black" : "white"
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
            currentIndex = privateMode ? 1 : 0
            tabPage.backNavigation = false
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
                    portrait: root.portrait
                    model: !root.privateMode ? root.tabModel : null

                    onHide: root.hide()
                    onEnterNewTabUrl: root.enterNewTabUrl()
                    onActivateTab: root.activateTab(index)
                    onCloseTab: root.closeTab(index)
                    onCloseAll: root.closeAll()
                    onCloseAllCanceled: root.closeAllCanceled()
                    onCloseAllPending: root.closeAllPending()
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
                    portrait: root.portrait
                    model: root.privateMode ? root.tabModel : null

                    onHide: root.hide()
                    onEnterNewTabUrl: root.enterNewTabUrl()
                    onActivateTab: root.activateTab(index)
                    onCloseTab: root.closeTab(index)
                    onCloseAll: root.closeAll()
                    onCloseAllCanceled: root.closeAllCanceled()
                    onCloseAllPending: root.closeAllPending()
                }
            }
        }

        ListModel {
            id: headerModel

            ListElement {
                icon: ""
            }
            ListElement {
                icon: ""
            }
        }

        function _updateHeaderModel() {
            headerModel.set(0, { "icon": persistentIcon.grabIcon })
            headerModel.set(1, { "icon": privateIcon.grabIcon })
        }

        children: [
            Image {
                id: persistentIcon
                property string grabIcon

                function updateGrubImage() {
                    persistentIcon.grabToImage(function(result) {
                        grabIcon = result.url
                        tabs._updateHeaderModel()
                    });
                }

                source: "image://theme/icon-m-tabs"
                Label {
                    anchors.centerIn: parent
                    text: webView.persistentTabModel.count
                    font.pixelSize: Theme.fontSizeExtraSmall
                    font.bold: true
                }
            },
            Item {
                id: privateIcon
                property string grabIcon

                function updateGrubImage() {
                    privateIcon.grabToImage(function(result) {
                        grabIcon = result.url
                        tabs._updateHeaderModel()
                    });
                }
                height: _privateIcon.implicitHeight
                width: _privateIcon.implicitWidth

                Image {
                    id: _privateIcon

                    source: webView.privateTabModel.count > 0 ? "image://theme/icon-m-incognito-selected" : "image://theme/icon-m-incognito"
                    visible: false
                }
                Rectangle {

                    anchors.fill: _privateIcon
                    color: "transparent"
                    Label {
                        anchors.centerIn: parent
                        text: webView.privateTabModel.count > 0 ? webView.privateTabModel.count : ""
                        font.pixelSize: Theme.fontSizeExtraSmall
                        font.bold: true
                    }

                    layer.enabled: true
                    layer.samplerName: "maskSource"
                    layer.effect: ShaderEffect {
                        property variant source: _privateIcon
                        fragmentShader: "
                                varying highp vec2 qt_TexCoord0;
                                uniform highp float qt_Opacity;
                                uniform lowp sampler2D source;
                                uniform lowp sampler2D maskSource;
                                void main(void) {
                                    gl_FragColor = texture2D(source, qt_TexCoord0.st) * (1.0-texture2D(maskSource, qt_TexCoord0.st).a) * qt_Opacity;
                                }
                            "
                    }
                }
            }

        ]
    }
    TabsToolBar {
        id: tabsToolBar
        anchors.bottom: parent.bottom
        onBack: pageStack.pop()
        onEnterNewTabUrl: root.enterNewTabUrl()
        onCloseAll: {
            _remorsePopup = Remorse.popupAction(
                        root,
                        //% "Closed all tabs"
                        qsTrId("sailfish_browser-closed-all-tabs"),
                        function() {
                            root.closeAll()
                            _remorsePopup = null
                        })
            closingAllTabs = true
            _remorsePopup.canceled.connect(
                        function() {
                            //closingAllTabs = false
                            root.closeAllCanceled()
                            _remorsePopup = null
                        })
        }
    }

    Connections {
        target: tabModel
        onCountChanged: {
            persistentIcon.updateGrubImage()
            privateIcon.updateGrubImage()
        }
    }

    // NOTE: Required to force update icons on tabs
    Connections {
        target: Theme
        onColorSchemeChanged: {
            persistentIcon.updateGrubImage()
            privateIcon.updateGrubImage()
        }
    }
}
