import QtQuick 2.0
import SddmComponents 2.0
import QtQuick.Layouts 1.2

Rectangle {
    id: root
    width: 640
    height: 480

    property color night: "#0a0e1a"
    property color night2: "#131829"
    property color accent: "#a78bfa"
    property color calm: "#c7d2fe"
    property color dim: "#94a3b8"

    property string uiFont: "DejaVu Sans"
    property string clockFont: "DejaVu Sans"

    // Variables para widgets
    property string weatherTemp: "..."
    property string weatherDesc: "Cargando..."
    property string weatherIcon: "☁"
    
    property string musicStatus: "Stopped"
    property string currentSong: "No reproduciendo"
    property string currentArtist: ""
    
    property string batteryStatus: "AC"
    property string batteryPercent: "100"
    property string batteryIcon: "⚡"
    
    property string cpuUsage: "0"
    property string ramUsage: "0"
    property string systemUptime: "..."

    TextConstants { id: textConstants }

    function pad2(n) { 
        return (n < 10 ? "0" : "") + n 
    }
    
    function dayNameEs(d) {
        var days = ["DOMINGO","LUNES","MARTES","MIERCOLES","JUEVES","VIERNES","SABADO"]
        return days[d]
    }
    
    function monthNameEs(m) {
        var months = ["ENERO","FEBRERO","MARZO","ABRIL","MAYO","JUNIO","JULIO","AGOSTO","SEPTIEMBRE","OCTUBRE","NOVIEMBRE","DICIEMBRE"]
        return months[m]
    }
    
    function formatDaySpaced(dayName) {
        var spaced = ""
        for (var i = 0; i < dayName.length; i++) {
            spaced += dayName[i]
            if (i < dayName.length - 1) spaced += " "
        }
        return spaced
    }
    
    function updateClock() {
        var now = new Date()
        dayBig.text = formatDaySpaced(dayNameEs(now.getDay()))
        dateMid.text = now.getDate() + " " + monthNameEs(now.getMonth()) + ", " + now.getFullYear() + "."
        timeSmall.text = "- " + pad2(now.getHours()) + ":" + pad2(now.getMinutes()) + " -"
    }

    // Actualizar clima desde script
    function updateWeather() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///usr/share/sddm/themes/maldives/scripts/weather.sh")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var data = xhr.responseText.trim().split("|")
                if (data.length >= 3) {
                    weatherTemp = data[0]
                    weatherDesc = data[1]
                    weatherIcon = data[2]
                }
            }
        }
        xhr.send()
    }

    // Actualizar música
    function updateMusic() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///usr/share/sddm/themes/maldives/scripts/music.sh")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var data = xhr.responseText.trim().split("|")
                if (data.length >= 3) {
                    musicStatus = data[0]
                    currentSong = data[1] || "Sin titulo"
                    currentArtist = data[2] || "Desconocido"
                }
            }
        }
        xhr.send()
    }

    // Actualizar batería
    function updateBattery() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///usr/share/sddm/themes/maldives/scripts/battery.sh")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var data = xhr.responseText.trim().split("|")
                if (data.length >= 3) {
                    batteryStatus = data[0]
                    batteryPercent = data[1]
                    batteryIcon = data[2]
                }
            }
        }
        xhr.send()
    }

    // Actualizar sistema
    function updateSystem() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file:///usr/share/sddm/themes/maldives/scripts/system.sh")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var data = xhr.responseText.trim().split("|")
                if (data.length >= 3) {
                    cpuUsage = data[0]
                    ramUsage = data[1]
                    systemUptime = data[2]
                }
            }
        }
        xhr.send()
    }

    function selectedUser() {
        var u = ""
        var i = userBox.index

        if (userModel && userModel.get) {
            var obj = userModel.get(i)
            if (obj) {
                u = obj.name || obj.userName || obj.login || obj.username || obj.user || ""
            }
        }

        if (!u && userBox.currentText) u = userBox.currentText
        if (!u && userModel && userModel.lastUser) u = userModel.lastUser

        return u
    }

    function doLogin() {
        var u = selectedUser()
        if (!u) {
            statusText.color = "#ef4444"
            statusText.text = "Selecciona un usuario"
            return
        }
        sddm.login(u, passBox.text, sessionBox.index)
    }

    Connections {
        target: sddm
        onLoginSucceeded: {
            statusText.color = "#10b981"
            statusText.text = "Ingresando..."
        }
        onLoginFailed: {
            passBox.text = ""
            statusText.color = "#ef4444"
            statusText.text = "Contrasena incorrecta"
        }
        onInformationMessage: {
            statusText.color = calm
            statusText.text = message
        }
    }

    Background {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        onStatusChanged: {
            if (status === Image.Error && source !== config.defaultBackground)
                source = config.defaultBackground
        }
    }

    Rectangle {
        anchors.fill: parent
        color: night
        opacity: 0.35
    }

    // Timer principal - actualiza todo
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateClock()
            
            // Actualizar widgets cada segundo (puedes cambiar la frecuencia)
            if (root.visible) {
                updateBattery()
                updateSystem()
            }
        }
    }

    // Timer para clima (cada 10 minutos)
    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateWeather()
    }

    // Timer para música (cada 3 segundos)
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateMusic()
    }
    
    Component.onCompleted: {
        updateClock()
        updateWeather()
        updateMusic()
        updateBattery()
        updateSystem()
        passBox.focus = true
    }

    // ============================================
    // RELOJ CENTRAL (estilo Rainmeter)
    // ============================================
    Column {
        id: clockColumn
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -200
        anchors.verticalCenterOffset: -60
        spacing: 8

        Text {
            id: dayBig
            anchors.horizontalCenter: parent.horizontalCenter
            text: "V I E R N E S"
            font.family: clockFont
            font.pixelSize: 68
            font.weight: Font.Bold
            font.letterSpacing: 12
            color: "#ffffff"
            opacity: 0.95
        }

        Text {
            id: dateMid
            anchors.horizontalCenter: parent.horizontalCenter
            text: "17 ENERO, 2026."
            font.family: uiFont
            font.pixelSize: 16
            font.weight: Font.Normal
            font.letterSpacing: 1.5
            color: dim
            opacity: 0.8
        }

        Text {
            id: timeSmall
            anchors.horizontalCenter: parent.horizontalCenter
            text: "- 14:30 -"
            font.family: clockFont
            font.pixelSize: 20
            font.weight: Font.Normal
            font.letterSpacing: 2
            color: "#ffffff"
            opacity: 0.7
        }
    }

    // ============================================
    // WIDGET CLIMA (abajo izquierda)
    // ============================================
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 50
        anchors.bottomMargin: 50

        width: 220
        height: 110
        radius: 18
        color: night2
        opacity: 0.8
        border.width: 1
        border.color: Qt.rgba(0.65, 0.54, 0.98, 0.35)

        Row {
            anchors.centerIn: parent
            spacing: 18

            Text {
                text: weatherIcon
                font.pixelSize: 48
                color: calm
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: weatherTemp
                    font.family: clockFont
                    font.pixelSize: 32
                    font.bold: true
                    color: "#ffffff"
                }

                Text {
                    text: weatherDesc
                    font.family: uiFont
                    font.pixelSize: 10
                    color: dim
                    opacity: 0.8
                    width: 100
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: "Lima, PE"
                    font.family: uiFont
                    font.pixelSize: 9
                    color: dim
                    opacity: 0.6
                }
            }
        }
    }

    // ============================================
    // WIDGET MUSICA (bajo el reloj)
    // ============================================
    Rectangle {
        anchors.left: clockColumn.left
        anchors.top: clockColumn.bottom
        anchors.topMargin: 40

        width: 320
        height: 85
        radius: 16
        color: night2
        opacity: musicStatus === "Playing" ? 0.85 : 0.5
        border.width: 1
        border.color: Qt.rgba(0.65, 0.54, 0.98, musicStatus === "Playing" ? 0.5 : 0.25)

        visible: musicStatus !== "Stopped"

        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // Icono animado si está reproduciendo
            Rectangle {
                width: 55
                height: 55
                radius: 10
                color: accent
                opacity: musicStatus === "Playing" ? 0.4 : 0.2
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: musicStatus === "Playing" ? "▶" : "⏸"
                    font.pixelSize: 26
                    color: calm
                }

                SequentialAnimation on opacity {
                    running: musicStatus === "Playing"
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.6; duration: 800 }
                    NumberAnimation { to: 0.4; duration: 800 }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                width: parent.width - 80

                Text {
                    text: currentSong
                    font.family: uiFont
                    font.pixelSize: 14
                    font.bold: true
                    color: calm
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: currentArtist
                    font.family: uiFont
                    font.pixelSize: 11
                    color: dim
                    opacity: 0.75
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }
    }

    // ============================================
    // WIDGET BATERIA (arriba derecha)
    // ============================================
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 50
        anchors.topMargin: 50

        width: 180
        height: 70
        radius: 14
        color: night2
        opacity: 0.75
        border.width: 1
        border.color: Qt.rgba(0.65, 0.54, 0.98, 0.3)

        Row {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: batteryIcon
                font.pixelSize: 32
                color: parseInt(batteryPercent) < 20 ? "#ef4444" : calm
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: batteryPercent + "%"
                    font.family: clockFont
                    font.pixelSize: 24
                    font.bold: true
                    color: "#ffffff"
                }

                Text {
                    text: batteryStatus === "Charging" ? "Cargando" : 
                          batteryStatus === "Discharging" ? "Bateria" : "AC"
                    font.family: uiFont
                    font.pixelSize: 9
                    color: dim
                    opacity: 0.7
                }
            }
        }
    }

    // ============================================
    // WIDGET SISTEMA (arriba izquierda)
    // ============================================
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 50
        anchors.topMargin: 50

        width: 240
        height: 90
        radius: 14
        color: night2
        opacity: 0.75
        border.width: 1
        border.color: Qt.rgba(0.65, 0.54, 0.98, 0.3)

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // CPU y RAM
            Row {
                width: parent.width
                spacing: 15

                Column {
                    spacing: 3
                    Text {
                        text: "CPU"
                        font.family: uiFont
                        font.pixelSize: 9
                        font.bold: true
                        color: dim
                        opacity: 0.7
                    }
                    Text {
                        text: cpuUsage + "%"
                        font.family: clockFont
                        font.pixelSize: 20
                        font.bold: true
                        color: calm
                    }
                }

                Column {
                    spacing: 3
                    Text {
                        text: "RAM"
                        font.family: uiFont
                        font.pixelSize: 9
                        font.bold: true
                        color: dim
                        opacity: 0.7
                    }
                    Text {
                        text: ramUsage + "%"
                        font.family: clockFont
                        font.pixelSize: 20
                        font.bold: true
                        color: calm
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: accent
                opacity: 0.2
            }

            // Uptime
            Text {
                text: "⏱ " + systemUptime
                font.family: uiFont
                font.pixelSize: 10
                color: dim
                opacity: 0.8
            }
        }
    }

    // ============================================
    // PANEL LOGIN (derecha)
    // ============================================
    Rectangle {
        id: panel
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 60

        width: 460
        height: contentCol.height + 80
        radius: 22

        color: "#12171f"
        opacity: 0.88
        border.width: 1
        border.color: Qt.rgba(0.65, 0.54, 0.98, 0.4)

        Rectangle {
            anchors.fill: parent
            anchors.margins: -10
            radius: parent.radius + 4
            color: "#000000"
            opacity: 0.5
            z: -2
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0.78, 0.82, 0.99, 0.15)
            z: -1
        }

        Column {
            id: contentCol
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 18

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "INICIO DE SESION"
                    font.family: clockFont
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    font.letterSpacing: 3
                    color: calm
                    opacity: 0.95
                }
                
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 80
                    height: 2
                    radius: 1
                    color: accent
                    opacity: 0.5
                }
            }

            Item { height: 4 }

            Column {
                width: parent.width
                spacing: 8
                
                Text {
                    text: "USUARIO"
                    font.family: uiFont
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.bold: true
                    color: dim
                    opacity: 0.7
                }

                Rectangle {
                    width: parent.width
                    height: 54
                    radius: 14
                    color: night2
                    opacity: 0.7
                    border.width: 1
                    border.color: Qt.rgba(0.65, 0.54, 0.98, 0.5)

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 2
                        border.color: accent
                        opacity: userBox.activeFocus ? 0.6 : 0
                        
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    ComboBox {
                        id: userBox
                        anchors.fill: parent
                        anchors.margins: 12
                        font.pixelSize: 15
                        arrowIcon: "angle-down.png"
                        model: userModel
                        index: userModel.lastIndex

                        KeyNavigation.tab: passBox
                        KeyNavigation.backtab: rebootButton
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 8
                
                Text {
                    text: "CONTRASENA"
                    font.family: uiFont
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.bold: true
                    color: dim
                    opacity: 0.7
                }

                Rectangle {
                    width: parent.width
                    height: 54
                    radius: 14
                    color: night2
                    opacity: 0.7
                    border.width: 1
                    border.color: Qt.rgba(0.65, 0.54, 0.98, 0.5)

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 2
                        border.color: accent
                        opacity: passBox.activeFocus ? 0.6 : 0
                        
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    PasswordBox {
                        id: passBox
                        anchors.fill: parent
                        anchors.margins: 12
                        font.pixelSize: 15

                        KeyNavigation.tab: sessionBox
                        KeyNavigation.backtab: userBox

                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                doLogin()
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 12

                Column {
                    width: (parent.width - 12) * 0.58
                    spacing: 8
                    
                    Text { 
                        text: "SESION"
                        font.family: uiFont
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                        font.bold: true
                        color: dim
                        opacity: 0.7
                    }

                    Rectangle {
                        width: parent.width
                        height: 50
                        radius: 14
                        color: night2
                        opacity: 0.7
                        border.width: 1
                        border.color: Qt.rgba(0.65, 0.54, 0.98, 0.5)

                        ComboBox {
                            id: sessionBox
                            anchors.fill: parent
                            anchors.margins: 10
                            font.pixelSize: 14
                            arrowIcon: "angle-down.png"
                            model: sessionModel
                            index: sessionModel.lastIndex

                            KeyNavigation.tab: layoutBox
                            KeyNavigation.backtab: passBox
                        }
                    }
                }

                Column {
                    width: (parent.width - 12) * 0.42
                    spacing: 8
                    
                    Text { 
                        text: "TECLADO"
                        font.family: uiFont
                        font.pixelSize: 10
                        font.letterSpacing: 1.5
                        font.bold: true
                        color: dim
                        opacity: 0.7
                    }

                    Rectangle {
                        width: parent.width
                        height: 50
                        radius: 14
                        color: night2
                        opacity: 0.7
                        border.width: 1
                        border.color: Qt.rgba(0.65, 0.54, 0.98, 0.5)

                        LayoutBox {
                            id: layoutBox
                            anchors.fill: parent
                            anchors.margins: 10
                            font.pixelSize: 14
                            arrowIcon: "angle-down.png"

                            KeyNavigation.tab: loginButton
                            KeyNavigation.backtab: sessionBox
                        }
                    }
                }
            }

            Text {
                id: statusText
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Presiona Enter"
                font.family: uiFont
                font.pixelSize: 11
                font.letterSpacing: 0.8
                color: calm
                opacity: 0.75
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Button {
                    id: loginButton
                    text: "ENTRAR"
                    width: 115
                    onClicked: doLogin()
                    KeyNavigation.tab: shutdownButton
                    KeyNavigation.backtab: layoutBox
                }
                Button {
                    id: shutdownButton
                    text: "APAGAR"
                    width: 115
                    onClicked: sddm.powerOff()
                    KeyNavigation.tab: rebootButton
                    KeyNavigation.backtab: loginButton
                }
                Button {
                    id: rebootButton
                    text: "REINICIAR"
                    width: 115
                    onClicked: sddm.reboot()
                    KeyNavigation.tab: userBox
                    KeyNavigation.backtab: shutdownButton
                }
            }
        }
    }
}
