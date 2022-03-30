import 'dart:ui';
import 'package:box3/screens/FullPicture.dart';
import 'package:box3/screens/box.dart';
import 'package:box3/screens/home.dart';
import 'package:box3/screens/home2.dart';
import 'package:box3/screens/signin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:box3/screens/GoogleAuthClient.dart'; //มีแค่นี้
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/cloudasset/v1.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;
import 'dart:async';

class Mycheck extends StatefulWidget {
  final FirebaseUser user;

  Mycheck(this.user, {Key key}) : super(key: key);

  @override
  _MycheckState createState() => _MycheckState();
}

class _MycheckState extends State<Mycheck> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  drive.FileList list;
  @override
  initState() {
    super.initState();
    checkBOX2();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue[600],
                Colors.blue,
              ],
            ),
          ),
          child: Container(
            child: Image.asset('images/wait.png'),
            alignment: Alignment.center,
          )),
    );
  }

  Future checkAuth2(BuildContext context) async {
    FirebaseUser user = await _auth.currentUser();
    if (user != null) {
      print("sign-in with google acount");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyHomePage(user)));
    } else if (user == null) {
      print("sign-out with google acount");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyLoginPage()));
    }
  }

  Future checkAuth3(BuildContext context) async {
    FirebaseUser user = await _auth.currentUser();
    if (user != null) {
      print("sign-in with google acount");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyHomePage2(user)));
    } else if (user == null) {
      print("sign-out with google acount");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyLoginPage()));
    }
  }

  Future<void> checkBOX2() async {
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
            supportsAllDrives: false,
            spaces: "drive",
            $fields: "files(id, name, mimeType, thumbnailLink)")
        .then((value) {
      setState(() {
        list = value;
      });
      var x = 0;
      for (var i = 0; i < list.files.length; i++) {
        String name = list.files[i].name;
        if (name == 'BOX' && list.files[i].mimeType.contains("folder")) {
          x = x + 1;
        }
        if (i == list.files.length - 1) {
          print(x);
          print('list2.files.length = ${list.files.length}');
          if (x == 1 || x < 1) {
            print('x=1');
            checkAuth2(context);
          } else if (x > 1) {
            print('x!=1');
            checkAuth3(context);
          }
        }
      }
    });
  }
/*
  signOut() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    );
    await _auth.signOut();
    await _googleSignIn.signOut();
    checkAuth2(context);
  }*/
/* 
  Future<void> listGoogleDriveFiles(String nameBox, String idBox) async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();

    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    print("idBoxListGoogleDriveFiles() = $idBox");
    print("driveApi=$driveApi");
    driveApi.files
        .list(
            q: '"$idBox" in parents',
            pageSize: null,
            supportsAllDrives: false,
            $fields: "files(id, name, mimeType, thumbnailLink, webViewLink)")
        .then((value) {
      setState(() {
        list = value;
      });
      for (var i = 0; i < list.files.length; i++) {
        print("Number:${[
          i + 1
        ]} Id: ${list.files[i].id} File Name:${list.files[i].name}Type:${list.files[i].mimeType} Url:${list.files[i].thumbnailLink} webViewLink:${list.files[i].webViewLink}");
      }
    });
  }*/
}
