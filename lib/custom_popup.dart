import 'package:flutter/material.dart';

class CustomPopup extends StatefulWidget {
  static CustomPopupState of(BuildContext context) =>
      context.findAncestorStateOfType<CustomPopupState>();
  final Icon icon;

  CustomPopup({Key key, this.icon}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return CustomPopupState();
  }
}

class CustomPopupState extends State<CustomPopup> {
  Future<void> _initializePopupFuture;
  int duration = 30;
  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: duration.toString());
  }

  @override
  Widget build(BuildContext context) {
    return _buildDialogContent(widget.icon);
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  Container _buildDialogContent(Icon icon) {
    return Container(
      padding: EdgeInsets.all(5.0),
      width: 279.0,
      height: 256.0,
      child: Stack(
        children: <Widget>[
          _buildTypeDurationAndLocation(icon),
          _editTextField()
          //_buildPopupContainer(icon),
          /*Container(
            margin: const EdgeInsets.only(top: 159.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ,
              ],
            ),
          ),*/
        ],
      ),
    );
  }

  Widget _editTextField() {
    if (_isEditingText)
      return Center(
        child: TextField(
          onSubmitted: (newValue) {
            setState(() {
              duration = int.parse(newValue);
              _isEditingText = false;
            });
          },
          autofocus: true,
          controller: _editingController,
        ),
      );
    return InkWell(
        onTap: () {
          setState(() {
            _isEditingText = true;
          });
        },
        child: Text(
          duration.toString(),
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.0,
          ),
        ));
  }

  Widget _buildPopupContainer(Icon icon) {
    return Container(
      color: Colors.white,
      height: 172.0,
      child: Stack(
        children: <Widget>[
          FutureBuilder(
            future: _initializePopupFuture,
            builder: (context, snapshot) {
              return Container(
                color: Colors.white,
                height: 172.0,
                child: Stack(children: <Widget>[]),
              );
              //: Center(child: CircularProgressIndicator());
            },
          ),
          Container(
            child: Stack(
              children: <Widget>[
                Center(
                  child:
                      Image.asset('assets/images/ic_blurred_gray_circle.png'),
                ),
                Center(
                  child: Container(
                    child: icon,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  bool _isEditingText = false;
  TextEditingController _editingController;

  Row _buildTypeDurationAndLocation(Icon icon) {
    var editableText = Text(duration.toString());
    return Row(children: [
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(left: 6.0, top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  icon.icon.toString() == 'IconData(U+0E800)'
                      ? Text('Traffic jam')
                      : Text('Broken street lamp')
                ],
              ),
              Row(
                children: <Widget>[
                  Text('Duration: '),
                  editableText,
                  Text(' mins'),
                  /*Expanded(
                  child: Text(
                    '6',
                    textAlign: TextAlign.end,
                  ),
                )*/
                ],
              ),
            ],
          ),
        ),
      )
    ]);
  }
}
