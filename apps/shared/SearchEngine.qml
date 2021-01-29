import QtQuick 2.0
import Sailfish.Browser 1.0

IconFetcher {
    property bool available
    property string get
    property string href
    property string title
    signal engineSaved

    function addSearchEngine() {
        fetch(href);
    }

    onStatusChanged: {
        if (status == IconFetcher.Ready) {
            if (saveAsSearchEngine())
                engineSaved();
        }
    }
}
