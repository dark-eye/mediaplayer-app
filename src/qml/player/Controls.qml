/*
 * Copyright (C) 2013 Canonical, Ltd.
 *
 * Authors:
 *  Ugo Riboni <ugo.riboni@canonical.com>
 *  Michał Sawicz <michal.sawicz@canonical.com>
 *  Renato Araujo Oliveira Filho <renato@canonical.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.0
import Ubuntu.Components 0.1
import "../sdk"

Item {
    id: controls

    property variant video: null
    property int sceneSelectorHeight : 0

    signal fullscreenButtonClicked
    signal playbackButtonClicked
    signal settingsClicked
    signal seekRequested(int time)
    signal startSeek
    signal endSeek

    focus: true

    function removeExt(uri) {
        return uri.toString().substring(0, uri.toString().lastIndexOf("."))
    }

    Item {
        id: _contents

        anchors.fill: parent

        ListModel {
            id: _sceneSelectorModel
        }

        SharePopover {
            id: _sharePopover

            visible: false
        }

        Item {
            id: _mainContainer

            Rectangle {
                color: "black"
                opacity: 0.7
                anchors {
                    top: _sceneSelector.visible ? _sceneSelector.top : _divLine.top
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                }
            }

            anchors.fill: parent

            SceneSelector {
                id: _sceneSelector

                property bool show: false
                property int yOffset: 0
                property bool parentActive: _controls.active

                y: (parent.y + units.gu(2)) + yOffset
                opacity: 0
                visible: opacity > 0
                height: controls.sceneSelectorHeight
                model: _sceneSelectorModel
                anchors {
                    left: parent.left
                    right: parent.right                    
                }

                onSceneSelected: {
                    controls.seekRequested(start)
                }

                onParentActiveChanged: {
                    if (!parentActive) {
                        show = false
                    }
                }

                ParallelAnimation {
                    id: _showAnimation

                    running: _sceneSelector.show
                    NumberAnimation { target: _sceneSelector; property: "opacity"; to: 1; duration: 150 }
                    NumberAnimation { target: _sceneSelector; property: "yOffset"; to: 0; duration: 150 }
                }

                ParallelAnimation {
                    id: _hideAnimation

                    running: !_sceneSelector.show
                    NumberAnimation { target: _sceneSelector; property: "opacity"; to: 0; duration: 150 }
                    NumberAnimation { target: _sceneSelector; property: "yOffset"; to: units.gu(2); duration: 150 }
                }
            }

            HLine {
                id: _divLine
                anchors {
                    bottom: _fullScreenButton.top
                    bottomMargin: units.gu(2)
                }
            }

            IconButton {
                id: _fullScreenButton

                iconSource: "artwork/full_scrn_icon.png"
                iconSize: units.gu(3)
                anchors {
                    left: parent.leftSharePopover
                    bottom: parent.bottom
                    bottomMargin: units.gu(2)
                }
                width: units.gu(9)
                height: units.gu(3)
                onClicked: controls.fullscreenClicked()
            }

            IconButton {
                id: _playbackButtom

                property string icon

                iconSource: icon ? "artwork/%1_icon.png".arg(icon) : ""
                iconSize: units.gu(3)
                anchors {
                    left: _fullScreenButton.right
                    leftMargin: _timeLineAnchor.visible ? units.gu(9) : units.gu(2)
                    bottom: parent.bottom
                    bottomMargin: units.gu(2)
                }
                width: units.gu(9)
                height: units.gu(3)

                onClicked: controls.playbackButtonClicked()
            }

            Item {
                id: _timeLineAnchor

                anchors {
                    left: _playbackButtom.right
                    right: _shareButton.left
                    rightMargin: units.gu(2)
                    bottom: parent.bottom
                    bottomMargin: units.gu(2)
                }
                height: units.gu(3)

                // does not show the slider if the space on the screen is not enough
                visible: (_timeLineAnchor.width > units.gu(5))

                TimeLine {
                    id: _timeline

                    property int maximumWidth: units.gu(82)
                    property bool seeking: false

                    anchors {                        
                        top: parent.top
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                    }

                    width: _timeLineAnchor.width >= maximumWidth ? maximumWidth : _timeLineAnchor.width
                    minimumValue: 0
                    maximumValue: video ? video.duration / 1000 : 0
                    value: video ? video.position / 1000 : 0

                    // pause the video during the seek
                    onPressedChanged: {
                       if (!pressed && seeking) {
                            endSeek()
                            seeking = false
                       }
                    }

                    // Live value is the real slider value. Ex: User dragging the slider
                    onLiveValueChanged: {
                        if (video && pressed)  {
                            var changed = Math.abs(liveValue - value)
                            if (changed > 1) {
                                if (!seeking) {
                                    startSeek()
                                    seeking = true
                                }
                                seekRequested(liveValue * 1000)
                                _sceneSelector.selectSceneAt(liveValue * 1000)
                            }
                        }
                    }

                    onValueChanged: _sceneSelector.selectSceneAt(video.position)

                    onClicked: {
                        if (insideThumb) {
                            _sceneSelector.show = !_sceneSelector.show
                        } else {
                            _sceneSelector.show = true
                        }
                    }
                }
            }

            IconButton {
                id: _shareButton

                iconSource: "artwork/share_icon.png"
                iconSize: units.gu(3)
                anchors {
                    right: _settingsButton.left
                    bottom: parent.bottom
                    bottomMargin: units.gu(2)
                }
                width: units.gu(9)
                height: units.gu(3)

                onClicked: {
                    var position = video.position
                    if (position === 0) {
                        if (video.duration > 10000) {
                            position = 10000;
                        } else if (video.duration > 0){
                            position = video.duration / 2
                        }
                    }
                    if (position >= 0) {
                        _sharePopover.picturePath = "image://video/" + video.source + "/" + position;
                    }
                    _sharePopover.caller = _shareButton
                    _sharePopover.show()
                }
            }

            IconButton {
                id: _settingsButton

                iconSource: "artwork/settings_icon.png"
                iconSize: units.gu(3)
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: units.gu(2)
                }

                width: units.gu(9)
                height: units.gu(3)

                onClicked: {
                    settingsClicked()
                }
            }
        }
    }

    Connections {
        target: video
        onDurationChanged: {
            _sceneSelector.currentIndex = -1
            _sceneSelectorModel.clear()
            // Only create thumbnails if video is bigger than 1min
            if (video.duration > 60000) {
                var frameSize = video.duration/10;
                for (var i = 0; i < 10; ++i) {
                    // TODO: discuss this with designers
                    // shift 3s to avoid black frame in the position 0
                    var pos = Math.floor(i * frameSize);
                    _sceneSelectorModel.append({"thumbnail": "image://video/" + video.source + "/" + (pos + 3000),
                                                "start" : pos,
                                                "duration" : frameSize})
                }
            }
        }
    }

    states: [
        State {
            name: "stopped"
            PropertyChanges { target: _playbackButtom; icon: "play" }
        },

        State {
            name: "playing"
            PropertyChanges { target: _playbackButtom; icon: "pause" }
        },

        State {
            name: "paused"
            PropertyChanges { target: _playbackButtom; icon: "play" }
        }
    ]
}