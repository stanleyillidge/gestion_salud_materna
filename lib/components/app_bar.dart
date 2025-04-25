import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/modelos.dart';
import '../pages/auth/login.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    this.customMenu,
    this.onTap,
    this.titulo,
    this.subtitulo,
    this.extra,
    required this.context,
    super.key,
    this.avatarUrl,
  });
  final Function()? customMenu;
  final Function(TapDownDetails)? onTap;
  final String? titulo;
  final String? subtitulo;
  final String? avatarUrl;
  final Widget? extra;
  final BuildContext? context;

  @override
  State<CustomAppBar> createState() => CustomAppBarState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomAppBarState extends State<CustomAppBar> {
  late Offset tapPosition;

  void storePosition(TapDownDetails details) {
    tapPosition = details.globalPosition;
  }

  void showCustomMenu() {
    showMenu(
      context: widget.context!,
      position: RelativeRect.fromRect(
          tapPosition & const Size(40, 40), // smaller rect, the touch area
          Offset.zero & const Size(40, 40) // Bigger rect, the entire screen
          ),
      items: {'Settings', 'Logout'}.map((String choice) {
        // final userProvider = Provider.of<UserProvider>(context);
        return PopupMenuItem<String>(
          onTap: () async {
            switch (choice) {
              case 'Logout':
                // print(['On icon action', a.toString()]);
                await Authentication().logout(context);
                break;
              case 'Settings':
                // _openFilterDialog();
                break;
              default:
            }
          },
          value: choice,
          child: Text(choice),
        );
      }).toList(),
    );
  }

  @override
  Widget build(context) {
    // Size size = MediaQuery.of(context).size;
    return AppBar(
      key: const ValueKey('CustomHomeAppBar'),
      // titleSpacing: widget.titleSpacing,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              (widget.titulo != null)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: (smallView) ? size.width * 0.45 : size.width * 0.15,
                          // size.width * ((mediumView || largeView) ? 0.5 : 0.6),
                          height: 27,
                          child: FittedBox(
                            alignment: Alignment.topLeft,
                            child: Text(
                              widget.titulo!,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              textAlign: TextAlign.start,
                              style: GoogleFonts.questrial(
                                // fontSize: 14,
                                letterSpacing: 0.25,
                                fontWeight: FontWeight.bold,
                                // color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          widget.subtitulo!,
                          style: GoogleFonts.questrial(
                            fontSize: 15,
                            letterSpacing: 1,
                            // fontWeight:
                            //     FontWeight.bold,
                            // color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
              (widget.titulo != null)
                  ? (widget.extra != null)
                      ? const SizedBox(
                          width: 20,
                        )
                      : const SizedBox()
                  : const SizedBox(),
              (widget.extra != null) ? widget.extra! : const SizedBox(),
            ],
          ),
          (kIsWeb)
              ? SizedBox(
                  // width: size.width * 0.55,
                  height: 45,
                  child: Container(
                    key: const ValueKey('CustomHomeAppBar-Container'),
                    alignment: Alignment.center,
                    width: size.width * 0.45,
                    height: 45,
                    decoration: BoxDecoration(
                      // color: primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 15,
                              height: 15,
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder: (Widget child, Animation<double> animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Icon(
                                key: UniqueKey(),
                                Icons.search,
                                size: 35,
                                // color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(),
          const SizedBox(
              // width: size.width * 0.05,
              ),
        ],
      ),
      actions: <Widget>[
        GestureDetector(
          onTap: widget.customMenu,
          onTapDown: widget.onTap,
          child: Card(
            elevation: 5,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(130.0)),
            ),
            child: CircleAvatar(
              backgroundImage: (widget.avatarUrl != null)
                  ? NetworkImage((widget.avatarUrl!.contains('https'))
                      ? widget.avatarUrl!
                      : 'https:${widget.avatarUrl}')
                  : const NetworkImage(
                      'https://randomuser.me/api/portraits/lego/1.jpg',
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
