import 'dart:ui';
import 'package:box3/screens/FullPicture.dart';
import 'package:box3/screens/box.dart';
import 'package:box3/screens/signin.dart';
import 'package:box3/screens/check.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:box3/screens/GoogleAuthClient.dart';
import 'package:googleapis/admin/directory_v1.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/cloudasset/v1.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/storagetransfer/v1.dart';
import 'package:path/path.dart' as path;
import 'dart:async';

class MyHomePage3 extends StatefulWidget {
  final FirebaseUser user;
  final String boxID, nameBox;

  MyHomePage3(this.user, this.boxID, this.nameBox, {Key key}) : super(key: key);

  @override
  _MyHomePage3State createState() => _MyHomePage3State();
}

class _MyHomePage3State extends State<MyHomePage3> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  drive.FileList list;
  drive.FileList list2;
  drive.FileList list3;
  String newName,
      idBox,
      boxID, //ไอดีของหน้าหลัก
      nameBox,
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
      shareName;
  String get newPath => _showDialog();
  String get newPath2 => search();
  //String get newPath3 => picturename();
  String get newPath4 => shareBOX();

  @override
  initState() {
    super.initState();
    setState(() {
      nameBox = widget.nameBox;
      boxID = widget.boxID;
      idBox = boxID;
      list = null;
      list2 = null;
    });
    listGoogleDriveFiles(nameBox, idBox);
    print('$nameBox $boxID');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$nameBox", style: TextStyle(color: Colors.white)),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.refresh),
              color: Colors.white,
              onPressed: () {
                listboxID(boxID);
              }),
          IconButton(
              icon: Icon(Icons.search),
              color: Colors.white,
              onPressed: () {
                search();
              }),
          IconButton(
              icon: Icon(Icons.share),
              color: Colors.white,
              onPressed: () {
                shareBOX();
              }),
        ],
      ),
      body: Container(
        child: ListView(
          children: generateFilesWidget(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          generateFilesWidget2();
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  Future checkAuth2(BuildContext context) async {
    FirebaseUser user = await _auth.currentUser();
    if (user != null) {
      print("sign-in with google acount");
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyBox(
                    user,
                    folderID,
                    folderName,
                    folderBoxID,
                    folderSearch,
                  )));
    } else if (user == null) {
      print("sign-out with google acount");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MyLoginPage()));
    }
  }

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
        ]} Id: ${list.files[i].id} File Name:${list.files[i].name} Type:${list.files[i].mimeType} Url:${list.files[i].thumbnailLink} webViewLink:${list.files[i].webViewLink}");
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

  Future<void> deleteFolder(String fileName, String googledriveID) async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();

    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    await driveApi.files.delete(googledriveID);
    print('name= $fileName  id = $googledriveID');
    print("Delete file ID: $googledriveID Result: ");
    listGoogleDriveFiles(nameBox, idBox);
    print('nameBox = $nameBox idBox = idBox');
  }

  List<Widget> generateFilesWidget() {
    List<Widget> listItem = List<Widget>();
    if (list != null) {
      for (var i = 0; i < list.files.length; i++) {
        Widget leadingIcon;
        if (list.files[i].mimeType.contains("folder")) {
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
                            folderID = list.files[i].id;
                            folderName = list.files[i].name;
                            folderBoxID = boxID;
                            folderSearch = null;
                          });
                          sendValueToBOX(context);
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 205.0,
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: Icon(
                              Icons.edit,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                picID = list.files[i].id;
                                picName = list.files[i].name;
                              });
                              picturename2();
                            },
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            child: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              deleteFolder(
                                  list.files[i].name, list.files[i].id);
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        } else if (list2 != null) {
          listItem.add(Container(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Container(
                  height: 250.0,
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text('รอซักครู่....'),
                ),
              ])));
        }
      }
    }
    return listItem;
  }

  createFolder() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();

    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    final driveFile = new drive.File();

    driveFile.parents = ["$idBox"];
    driveFile.name = '$newName';
    driveFile.mimeType = "application/vnd.google-apps.folder";
    final result = await driveApi.files.create(driveFile);
    print("Upload result: $result");
    listGoogleDriveFiles(nameBox, idBox);
  }

  Future<void> listGoogleDriveFiles2(
      String googledriveNAME, String googledriveID) async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();
    String idBox2 = googledriveID;
    String nameBox2 = googledriveNAME;
    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    print('googledriveID: $googledriveID');
    print('googledriveIDBox: $googledriveID');
    driveApi.files
        .list(
            q: "'$googledriveID' in parents",
            pageSize: null,
            supportsAllDrives: false,
            spaces: "drive",
            $fields: "files(id, name, mimeType, thumbnailLink, webViewLink)")
        .then((value) {
      setState(() {
        list = value;
      });
      for (var i = 0; i < list.files.length; i++) {
        print("Number:${[
          i + 1
        ]} Id: ${list.files[i].id} File Name:${list.files[i].name} Type:${list.files[i].mimeType} Url:${list.files[i].thumbnailLink} webViewLink:${list.files[i].webViewLink}");
      }
      setState(() {
        idBox = idBox2;
        nameBox = nameBox2;
      });
    });
  }

  _showDialog() async {
    await showDialog<String>(
      context: context,
      builder: (_) => new AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: new Row(
          children: <Widget>[
            new Expanded(
              child: new TextField(
                onChanged: (value) => newName = value,
                autofocus: true,
                decoration:
                    new InputDecoration(labelText: 'ชื่อกล่อง', hintText: ''),
              ),
            )
          ],
        ),
        actions: <Widget>[
          new TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.pop(context);
              }),
          new TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                print('newName: $newName');
                Navigator.pop(context);
                createFolder();
              })
        ],
      ),
    );
  }

  shareBOX() async {
    await showDialog<String>(
      context: context,
      builder: (_) => new AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: new Row(
          children: <Widget>[
            new Expanded(
              child: new TextField(
                onChanged: (value) => shareName = value,
                autofocus: true,
                decoration: new InputDecoration(
                    labelText: 'อีเมลล์ที่ต้องการแชร์', hintText: ''),
              ),
            )
          ],
        ),
        actions: <Widget>[
          new TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.pop(context);
              }),
          new TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                print('shareName: $shareName');
                Navigator.pop(context);
                share();
              })
        ],
      ),
    );
  }

  search() async {
    await showDialog<String>(
      context: context,
      builder: (_) => new AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: new Row(
          children: <Widget>[
            new Expanded(
              child: new TextField(
                onChanged: (value) => searchName = value,
                autofocus: true,
                decoration: new InputDecoration(
                    labelText: 'ชื่อสิ่งของที่ต้องการค้นหา', hintText: ''),
              ),
            )
          ],
        ),
        actions: <Widget>[
          new TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.pop(context);
              }),
          new TextButton(
              child: const Text('ค้นหา'),
              onPressed: () {
                print('searchName: $searchName');
                Navigator.pop(context);
                setState(() {
                  folderSearch = searchName;
                  folderBoxID = boxID;
                  folderID = idBox;
                  folderName = nameBox;
                });
                sendValueToBOX(context);
              })
        ],
      ),
    );
  }

  picturename2() async {
    await showDialog<String>(
      context: context,
      builder: (_) => new AlertDialog(
        contentPadding: const EdgeInsets.all(16.0),
        content: new Row(
          children: <Widget>[
            new Expanded(
              child: new TextField(
                onChanged: (value) => picName = value,
                autofocus: true,
                decoration:
                    new InputDecoration(labelText: 'ชื่อกล่อง', hintText: ''),
              ),
            )
          ],
        ),
        actions: <Widget>[
          new TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.pop(context);
              }),
          new TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                print('picName: $picName');
                Navigator.pop(context);
                rename();
              })
        ],
      ),
    );
  }

  Future rename() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();
    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    final driveFile = drive.File();
    driveFile.name = '$picName';
    driveApi.files.update(driveFile, picID);
    print('เปลี่ยนชื่อสำเร็จ');
    setState(() {
      list = null;
    });

    driveApi.files
        .list(
            q: '"$idBox" in parents',
            supportsAllDrives: false,
            spaces: "drive",
            $fields: "files(id, name, mimeType, thumbnailLink)")
        .then((value) {
      setState(() {
        list = null;
        list2 = value;
      });
      listGoogleDriveFiles(nameBox, idBox);
      print('nameBox = $nameBox idBox = $idBox');
    });
  }

  List<Widget> generateFilesWidget2() {
    List<Widget> listItem2 = List<Widget>();
    if (nameBox == 'BOX') {
      listItem2.add(
        _showDialog(),
      );
    }
    return listItem2;
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

  Future share() async {
    print('ShareName = $shareName');
    print('boxID = $boxID');
    final String name = shareName.toString();
    print(shareName);
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();
    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    final driveFile = new drive.Permission();

    driveFile.role = 'writer';
    driveFile.type = 'user';
    driveFile.emailAddress = name;
    print('ดักดู   ${driveFile.emailAddress}');
    // driveFile.kind = 'drive#permission';
    // driveFile.id = '06163652592434522150';
    await driveApi.permissions.create(driveFile, '$boxID');
    //driveApi.permissions.create('$shareName', '$boxID')
    print('Share folder to $shareName');
  }
}
   //driveFile.emailAddress = 'peath8285@gmail.com';
    //shareName = 'yourEmail@mail.com';
    // driveFile.emailAddress = shareName.toString();
    // print(shareName.toString());