import QtQuick
import Vinx.Theme
import Vinx.Controls
import Vinx.System

// Paramètres → Utilisateurs : comptes, création, mot de passe, type de compte, suppression.
Column {
    id: page
    spacing: Theme.space2
    property string message: ""
    property bool ok: true
    property string editing: ""        // chemin du compte dont le mot de passe est modifié
    property bool adding: false
    onVisibleChanged: if (visible) Accounts.refresh()
    Component.onCompleted: if (visible) Accounts.refresh()
    Connections { target: Accounts; function onFinished(success, msg) { page.message = msg; page.ok = success; if (success) { page.adding = false; page.editing = "" } } }

    component Field: Rectangle {
        property alias text: input.text
        property string placeholder
        property bool secret: false
        width: 260; height: 32; radius: Theme.radiusSm
        color: Theme.surfaceSunken; border.width: input.activeFocus ? 2 : 1
        border.color: input.activeFocus ? Theme.accentForeground : Theme.border
        TextInput {
            id: input
            anchors { fill: parent; leftMargin: Theme.space2; rightMargin: Theme.space2 }
            verticalAlignment: TextInput.AlignVCenter
            echoMode: parent.secret ? TextInput.Password : TextInput.Normal; passwordCharacter: "●"
            color: Theme.text; font.pixelSize: Theme.fsMd; clip: true
            Label { visible: !input.text; text: parent.parent.placeholder; level: Label.Tertiary; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    Label { visible: !Accounts.available; text: qsTr("Le service des comptes n'est pas disponible."); level: Label.Secondary }

    Repeater {
        model: Accounts.users
        delegate: Column {
            id: acc
            required property var modelData
            width: page.width
            SettingsRow {
                title: (modelData.realName || modelData.userName) + (modelData.current ? qsTr(" (vous)") : "")
                description: modelData.userName + " · " + (modelData.admin ? qsTr("Administrateur") : qsTr("Standard"))
                Row {
                    spacing: Theme.space2
                    Button { text: qsTr("Mot de passe…"); variant: Button.Secondary; onClicked: page.editing = page.editing === acc.modelData.path ? "" : acc.modelData.path }
                    Button {
                        visible: !acc.modelData.current
                        text: acc.modelData.admin ? qsTr("Rendre standard") : qsTr("Rendre administrateur")
                        variant: Button.Ghost
                        onClicked: Accounts.setAdmin(acc.modelData.path, !acc.modelData.admin)
                    }
                    Button { visible: !acc.modelData.current; text: qsTr("Supprimer"); variant: Button.Ghost; onClicked: confirm.uid = acc.modelData.uid }
                }
            }
            Row {
                visible: page.editing === acc.modelData.path
                spacing: Theme.space2; bottomPadding: Theme.space2
                Field { id: p1; placeholder: qsTr("Nouveau mot de passe"); secret: true; width: 200 }
                Field { id: p2; placeholder: qsTr("Confirmer"); secret: true; width: 200 }
                Button {
                    text: qsTr("Enregistrer"); variant: Button.Primary
                    enabled: p1.text.length >= 6 && p1.text === p2.text
                    onClicked: { Accounts.setPassword(acc.modelData.path, p1.text); p1.text = ""; p2.text = "" }
                }
            }
            // Confirmation de suppression
            Row {
                visible: confirm.uid === acc.modelData.uid
                spacing: Theme.space2; bottomPadding: Theme.space2
                Label { text: qsTr("Supprimer ce compte ?"); anchors.verticalCenter: parent.verticalCenter }
                Button { text: qsTr("Garder ses fichiers"); onClicked: { Accounts.deleteUser(acc.modelData.uid, false); confirm.uid = -1 } }
                Button { text: qsTr("Tout supprimer"); variant: Button.Primary; onClicked: { Accounts.deleteUser(acc.modelData.uid, true); confirm.uid = -1 } }
                Button { text: qsTr("Annuler"); variant: Button.Ghost; onClicked: confirm.uid = -1 }
            }
        }
    }
    QtObject { id: confirm; property var uid: -1 }

    // Nouveau compte
    MenuItem { width: parent.width; iconName: "plus"; text: qsTr("Ajouter un utilisateur…"); onTriggered: page.adding = !page.adding }
    Column {
        visible: page.adding
        spacing: Theme.space2
        Field {
            id: realName
            property string suggested: ""
            placeholder: qsTr("Nom complet (ex. Marie Dupont)")
            // Propose un identifiant tant que l'utilisateur ne l'a pas modifié lui-même.
            onTextChanged: { if (login.text === suggested) login.text = Accounts.suggestUserName(text); suggested = Accounts.suggestUserName(text) }
        }
        Field { id: login; placeholder: qsTr("Identifiant (minuscules)") }
        Field { id: np1; placeholder: qsTr("Mot de passe"); secret: true }
        Field { id: np2; placeholder: qsTr("Confirmer le mot de passe"); secret: true }
        Row {
            spacing: Theme.space2
            Label { text: qsTr("Administrateur"); anchors.verticalCenter: parent.verticalCenter }
            Switch { id: isAdmin }
        }
        Label {
            visible: login.text !== "" && !Accounts.validUserName(login.text)
            text: qsTr("Identifiant : lettres minuscules, chiffres, « - » ou « _ », sans espace.")
            color: Theme.danger; font.pixelSize: Theme.fsSm
        }
        Button {
            text: Accounts.busy ? qsTr("Création…") : qsTr("Créer le compte")
            variant: Button.Primary
            enabled: !Accounts.busy && Accounts.validUserName(login.text) && np1.text.length >= 6 && np1.text === np2.text
            onClicked: Accounts.createUser(login.text, realName.text, isAdmin.checked, np1.text)
        }
    }

    Label {
        visible: page.message !== ""
        width: parent.width; wrapMode: Text.WordWrap; topPadding: Theme.space2
        text: page.message
        color: page.ok ? Theme.accentForeground : Theme.danger
    }
    SettingsRow {
        title: qsTr("Comptes en ligne")
        description: qsTr("Google, Nextcloud… pour les fichiers et agendas.")
        Button { text: qsTr("Gérer…"); variant: Button.Ghost; onClicked: Session.launch("systemsettings", ["kcm_kaccounts"]) }
    }
}
