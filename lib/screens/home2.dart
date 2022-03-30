import 'dart:ui';
import 'package:box3/screens/FullPicture.dart';
import 'package:box3/screens/box.dart';
import 'package:box3/screens/home.dart';
import 'package:box3/screens/home3.dart';
import 'package:box3/screens/signin.dart';
import 'package:box3/screens/check.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:box3/screens/GoogleAuthClient.dart'; 
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/cloudasset/v1.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;
import 'dart:async';

class MyHomePage2 extends StatefulWidget {
  final FirebaseUser user;

  MyHomePage2(this.user, {Key key}) : super(key: key);

  @override
  _MyHomePage2State createState() => _MyHomePage2State();
}

class _MyHomePage2State extends State<MyHomePage2> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  drive.FileList list;
  drive.FileList list2;
  String newName,
      idBox,
      boxID, //ไอดีของหน้าหลัก
      searchName,
      picName,
      picID,
      picLINK,
      idLast,
      userName,
      folderID,
      folderName,
      folderBoxID,
      folderSearch,
      nameBox,
      shareName;
  int boxMe;

  @override
  initState() {
    super.initState();
    setState(() {
      list = null;
      list2 = null;
    });
    listGoogleDriveFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("กรุณาเลือกห้อง",
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
      ),
      drawer: showDrawer(),
      body: Container(
        child: ListView(
          children: generateFilesWidget(),
        ),
      ),
    );
  }

  Drawer showDrawer() => Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
                currentAccountPicture: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          fit: BoxFit.fill,
                          image: NetworkImage(widget.user.photoUrl))),
                ),
                accountName: Text(widget.user.displayName),
                accountEmail: Text(widget.user.email)),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('หน้าหลัก'),
              onTap: () {
                Navigator.pop(context);
                listGoogleDriveFiles();
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('ออกจากระบบ'),
              onTap: () {
                signOut();
              },
            )
          ],
        ),
      );

  Future checkAuth2(BuildContext context) async {
    FirebaseUser user = await _auth.currentUser();
    if (user != null) {
      print("sign-in with google acount");
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyHomePage3(user, boxID, nameBox)));
    } else if (user == null) {
      print("sign-out with google acount");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyLoginPage()));
    }
  }

  signOut() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    );
    await _auth.signOut();
    await _googleSignIn.signOut();
    checkAuth2(context);
  }

  Future<void> listGoogleDriveFiles() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();

    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    driveApi.files
        .list(
            pageSize: 1000,
            spaces: 'drive',
            supportsAllDrives: false,
            $fields: "files(id, name, mimeType, thumbnailLink, webViewLink)")
        .then((value) {
      setState(() {
        list = value;
      });
      List<int> listx = [];
      for (var i = 0; i < list.files.length; i++) {
        print("Number:${[
          i + 1
        ]} Id: ${list.files[i].id} File Name:${list.files[i].name} Type:${list.files[i].mimeType} Url:${list.files[i].thumbnailLink} webViewLink:${list.files[i].webViewLink}");
        if (list.files[i].name == 'BOX') {
          List<int> list = listx + [i];
          setState(() {
            boxMe = list[0];
            print('boxMe = $boxMe');
          });
        }
      }
    });
  }

  Future<void> listboxID(String boxID) async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();

    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    print("listboxID() = $boxID");
    print("driveApi=$authHeaders");
    driveApi.files
        .list(
            q: '"$boxID" in parents',
            pageSize: null,
            supportsAllDrives: false,
            $fields: "files(id, name, mimeType, thumbnailLink)")
        .then((value) {
      setState(() {
        list = value;
        list2 = value;
      });
      for (var i = 0; i < list.files.length; i++) {
        print("Number:${[
          i + 1
        ]} Id: ${list.files[i].id} File Name:${list.files[i].name} Type:${list.files[i].mimeType} Url:${list.files[i].thumbnailLink}");
        setState(() {
          nameBox = 'BOX';
          idBox = boxID;
        });
      }
    });
  }

  List<Widget> generateFilesWidget() {
    List<Widget> listItem = List<Widget>();
    if (list != null) {
      for (var i = 0; i < list.files.length; i++) {
        if (list.files[i].mimeType.contains("folder") &&
            list.files[i].name == 'BOX' &&
            '$i' == '$boxMe') {
          Widget leadingIcon;
          leadingIcon = Icon(
            Icons.folder,
            color: Colors.amber,
            size: 100,
          );
          listItem.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: ListTile(
                        leading: leadingIcon,
                        title: Text(list.files[i].name),
                        onTap: () {
                          setState(() {
                            boxID = list.files[i].id;
                            nameBox = list.files[i].name;
                            print('2 = $nameBox $boxID');
                          });
                          sendValueToBOX(context);
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 135.0,
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Text('กล่องของฉัน'),
                        ),
                      ],
                    ),
                    Container(
                      height: 30.0,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (list.files[i].mimeType.contains("folder") &&
            list.files[i].name == 'BOX' &&
            '$i' != '$boxMe') {
          Widget leadingIcon;
          leadingIcon = Icon(
            Icons.folder,
            color: Colors.amber,
            size: 100,
          );
          listItem.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: ListTile(
                        leading: leadingIcon,
                        title: Text(list.files[i].name),
                        onTap: () {
                          setState(() {
                            boxID = list.files[i].id;
                            nameBox = list.files[i].name;
                            print('2 = $nameBox $boxID');
                          });
                          sendValueToBOX(context);
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 135.0,
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Text('กล่องของเพื่อน'),
                        ),
                      ],
                    ),
                    Container(
                      height: 30.0,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    return listItem;
  }

  Future sendValueToBOX(BuildContext context) async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();
    GoogleSignInAuthentication userAuth = await user.authentication;

    await _auth.signInWithCredential(GoogleAuthProvider.getCredential(
        idToken: userAuth.idToken, accessToken: userAuth.accessToken));
    checkAuth2(context); // after success route to home.
  }
}
