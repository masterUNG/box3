import 'dart:ui';
import 'package:box3/screens/FullPicture.dart';
import 'package:box3/screens/signin.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:box3/screens/GoogleAuthClient.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyBox extends StatefulWidget {
  final FirebaseUser user;
  final String folderName;
  final String folderID;
  final String folderBoxID;
  final String folderSearch;
  MyBox(this.user, this.folderID, this.folderName, this.folderBoxID,
      this.folderSearch,
      {Key key})
      : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyBox> {
  File imageFile;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  drive.FileList list;
  drive.FileList list2;
  drive.FileList list3;
  String newName,
      idBox,
      boxID, //ไอดีของหน้าหลัก
      searchName,
      picName,
      picID,
      picLINK,
      idLast,
      userName;
  String nameBox = '';
  String get newPath3 => picturename();

  @override
  initState() {
    super.initState();
    print('ID');
    print(widget.folderID);
    print('Name');
    print(widget.folderName);
    print('BoxID');
    print(widget.folderBoxID);
    print('searchName');
    print(widget.folderSearch);
    setState(() {
      idBox = widget.folderID;
      nameBox = widget.folderName;
      boxID = widget.folderBoxID;
      searchName = widget.folderSearch;
    });
    if (searchName != null) {
      print('folderSearch = 1');
      setState(() {
        nameBox = '';
      });
      checkSearch();
    } else {
      listGoogleDriveFiles(nameBox, idBox);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$nameBox", style: TextStyle(color: Colors.white)),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.search),
              color: Colors.white,
              onPressed: () {
                search();
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

  Future<void> uploadFileToGoogleDrive() async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();

    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    drive.File fileToUpload = drive.File();;
    var file = imageFile;
    fileToUpload.parents = [idBox];
    print('idBoxupload2: $idBox');
    fileToUpload.name = path.basename(file.absolute.path);

    setState(() {
      list = null;
    });
    final result = await driveApi.files.create(
      fileToUpload,
      uploadMedia: drive.Media(
        file.openRead(),
        file.lengthSync(),
      ),
    );
    print("Upload result: $result");
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
        picID = list2.files[0].id;
        picName = list2.files[0].name;
      });
      picturename();
    });
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

  Future<void> deleteFile(String fileName, String googledriveID) async {
    GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveFileScope],
    );
    GoogleSignInAccount user = await _googleSignIn.signIn();

    final authHeaders = await user.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);
    final result = await driveApi.files.delete(googledriveID);
    print("Delete file ID: $googledriveID Result: ");
    listGoogleDriveFiles(nameBox, idBox);
  }

  List<Widget> generateFilesWidget() {
    List<Widget> listItem = List<Widget>();
    if (list != null) {
      for (var i = 0; i < list.files.length; i++) {
        if (list.files[i].webViewLink != null &&
            list.files[i].mimeType.contains("image")) {
          listItem.add(
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 100.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 15.0,
                    ),
                    Container(
                      width: double.infinity,
                      height: 200.0,
                      alignment: Alignment.center,
                      child: Image.network(
                        list.files[i].thumbnailLink,
                      ),
                    ),
                    Container(
                      height: 15.0,
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        list.files[i].name,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      height: 15.0,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 75.0,
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                picID = list.files[i].id;
                                picName = list.files[i].name;
                                picLINK = list.files[i].webViewLink;
                              });
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MyFullPicture(webviewLINK: picLINK)));
                            },
                          ),
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
                              picturename();
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
                              deleteFile(list.files[i].name, list.files[i].id);
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
        } 
      }
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
    } else if (list3 != null) {
      listItem.add(Container(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            Container(
              height: 250.0,
            ),
            Container(
              alignment: Alignment.center,
              child: Text('ไม่พบรูปภาพที่ท่านค้นหา'),
            ),
          ])));
    }
    return listItem;
  }

  picturename() async {
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
                    new InputDecoration(labelText: 'ชื่อรูปภาพ', hintText: ''),
              ),
            )
          ],
        ),
        actions: <Widget>[
          new TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.pop(context);
                deleteFile(picName, picID);
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
    });
  }

  List<Widget> generateFilesWidget2() {
    List<Widget> listItem2 = List<Widget>();
    if (nameBox == 'BOX') {
      print('folder box ไม่สามารถเพิ่มรูปภาพได้');
    } else if (nameBox != 'BOX') {
      showPicker(context);
    }
    return listItem2;
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
                  searchName = searchName;
                });
                checkSearch();
              })
        ],
      ),
    );
  }

  Future<void> checkSearch() async {
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
            q: '"$boxID" in parents',
            pageSize: null,
            supportsAllDrives: false,
            $fields: "files(id, name, mimeType, thumbnailLink, webViewLink)")
        .then((value) {
      setState(() {
        list = null;
        list2 = value;
        nameBox = 'กำลังค้นหา.....';
      });
      int x = 0;
      int b;
      for (var i = 0; i < list2.files.length; i++) {
        var searchID2 = list2.files[i].id;
        var idBox2 = list2.files[i].id;
        var nameBox2 = list2.files[i].name;
        print('ชื่อกล่อง = ${list2.files[i].name}');
        if (i == list2.files.length - 1) {
          print('สุดท้ายและว่าง= $i');
          print('idสุดท้ายและว่าง= ${list2.files[i].id}');
          b = i + 1;
          print('b = $b');
        }
        driveApi.files
            .list(
                q: '"$searchID2" in parents',
                supportsAllDrives: false,
                spaces: "drive",
                $fields: "files(id, name, mimeType, thumbnailLink)")
            .then((value) {
          setState(() {
            list = null;
            list2 = value;
          });
          x = x + 1;
          print('x = ');
          print('$x');
          for (var j = 0; j < list2.files.length; j++) {
            print('searchID2 = $searchID2');
            String name = list2.files[j].name;
            print('name befor if = $name');
            if (searchName == name) {
              print('namepic = $name');
              setState(() {
                idBox = idBox2;
                nameBox = nameBox2;
                list = value;
                list2 = null;
                list3 = null;
              });
              x = 100;
              listGoogleDriveFiles(nameBox, idBox);
              break;
            } else if (j == list2.files.length - 1 &&
                x == b &&
                searchName != name) {
              print('nameJ = $j');
              setState(() {
                list = null;
                list2 = null;
                list3 = value;
                nameBox = 'ไม่พบรูปภาพที่ท่านค้นหา';
              });
              break;
            }
          }
        });
      }
    });
  }

  /// Get from gallery
  _getFromGallery() async {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
      uploadFileToGoogleDrive();
    }
  }

  /// Get from Camera
  _getFromCamera() async {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
      uploadFileToGoogleDrive();
    }
  }

  void showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('แกลเลอรี'),
                      onTap: () {
                        _getFromGallery();
                        Navigator.of(context).pop();
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('กล้อง'),
                    onTap: () {
                      _getFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }
}
