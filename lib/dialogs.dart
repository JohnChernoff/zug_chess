import 'package:flutter/material.dart';
import 'package:zug_chess/zug_chess.dart';

class ChessDialogs {
  static Future<Piece?> pieceDialog(List<Piece> pieces, BuildContext context, {
    msg = 'Choose a piece'}) async {
    return showDialog<Piece>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(msg),
          content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(pieces.length, (i) =>  InkWell(
                child: Piece.imgMap[pieces.elementAt(i).toString()],
                onTap: () {
                  Navigator.of(context).pop(pieces.elementAt(i));
                },
              ))
          ),
        );
      },
    ).then((p) {
      return p;
    });
  }
}


