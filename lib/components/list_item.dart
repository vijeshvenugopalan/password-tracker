import 'package:flutter/material.dart';
import 'package:password_tracker/services/database_util.dart';
import 'package:password_tracker/state/data.dart';
import 'package:provider/provider.dart';

class ListItem extends StatelessWidget {
  final Item item;
  ListItem(this.item);

  @override
  Widget build(BuildContext context) {
    ItemData itemData = null;
    Data data = Provider.of<Data>(context);
    if (item.isFolder == 0) {
      itemData = data.getItemData(item.id);
    }
    return SizedBox(
      width: MediaQuery.of(context).size.width - 115,
      child: (item.isFolder == 1)
          ? Text(
              "${item.name}",
              overflow: TextOverflow.ellipsis,
            )
          : RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: "${item.name}",
                    style: Theme.of(context).textTheme.body1,
                  ),
                  TextSpan(
                    text: "\nusername: ",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.caption.color,
                      fontSize: Theme.of(context).textTheme.caption.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: "${itemData.username}",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.caption.color,
                      fontSize: Theme.of(context).textTheme.caption.fontSize,
                    ),
                  ),
                  TextSpan(
                    text: "\nurl: ",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.caption.color,
                      fontSize: Theme.of(context).textTheme.caption.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: "${itemData.url}",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.caption.color,
                      fontSize: Theme.of(context).textTheme.caption.fontSize,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
