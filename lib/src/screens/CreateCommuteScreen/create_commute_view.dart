import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:mbta_companion/src/models/commute.dart';
import 'package:mbta_companion/src/models/stop.dart';
import 'package:mbta_companion/src/screens/CreateCommuteScreen/utils/choose_stop.dart';
import 'package:mbta_companion/src/screens/CreateCommuteScreen/widgets/create_button.dart';
import 'package:mbta_companion/src/screens/CreateCommuteScreen/widgets/info_text.dart';
import 'package:mbta_companion/src/screens/CreateCommuteScreen/widgets/stop_container.dart';
import 'package:mbta_companion/src/screens/CreateCommuteScreen/widgets/time_selection_row.dart';
import 'package:mbta_companion/src/state/operations/commuteOperations.dart';
import 'package:mbta_companion/src/state/state.dart';
import 'package:redux/redux.dart';

class CreateCommuteScreen extends StatefulWidget {
  @override
  _CreateCommuteScreenState createState() => _CreateCommuteScreenState();
}

class _CreateCommuteScreenState extends State<CreateCommuteScreen> {
  String appBarText;
  Stop stop1, stop2;
  TimeOfDay arrivalTime, departureTime;

  initVariables(Commute commute) {
    if (commute != null) {
      if (isCommuteSwapped(commute)) {
        this.stop1 = commute.stop2;
        this.stop2 = commute.stop1;
        this.arrivalTime = commute.departureTime;
        this.departureTime = commute.arrivalTime;
      } else {
        this.stop1 = commute.stop1;
        this.stop2 = commute.stop2;
        this.arrivalTime = commute.arrivalTime;
        this.departureTime = commute.departureTime;
      }
      this.appBarText = "Update Commute";
    } else {
      this.arrivalTime = TimeOfDay(hour: 9, minute: 0);
      this.departureTime = TimeOfDay(hour: 17, minute: 0);
      this.appBarText = "Create Commute";
    }
  }

  bool isCommuteSwapped(Commute commute) {
    return !(commute.stop1.id == commute.homeStopId);
  }

  handleChosenStop(homeStop, context, {Stop currentStop}) async {
    Stop stop = await chooseStop(homeStop, context);

    if (!this.mounted) {
      return;
    }

    // nothing was tapped
    if (stop == null) {
      stop = currentStop;
    }

    if (homeStop) {
      setState(() {
        this.stop1 = stop;
      });
    } else {
      setState(() {
        this.stop2 = stop;
      });
    }
  }

  void pickTime(bool arrival) {
    showTimePicker(
      context: context,
      initialTime: arrival
          ? TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: 17, minute: 0),
    ).then((time) {
      if (time != null) {
        setState(() {
          arrival ? arrivalTime = time : departureTime = time;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, CreateCommuteViewModel>(
      converter: (store) => CreateCommuteViewModel.create(store),
      builder: (context, CreateCommuteViewModel viewModel) {
        initVariables(viewModel.commute);

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(appBarText),
          ),
          body: SafeArea(
            child: Container(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        stopContainer(context, true, "Home",
                            "Tap to add home stop", this.stop1),
                        stopContainer(context, false, "Work",
                            "Tap to add work stop", this.stop2),
                        timeSelectionRow(context, this.arrivalTime,
                            this.departureTime, pickTime),
                      ],
                    ),
                  ),
                  infoText(context),
                  createButton(context, appBarText, viewModel, this.stop1,
                      this.stop2, this.arrivalTime, this.departureTime),
                  Container(
                    height: 12.0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CreateCommuteViewModel {
  final Commute commute;
  final Function(Commute) saveCommute;

  CreateCommuteViewModel({this.commute, this.saveCommute});

  factory CreateCommuteViewModel.create(Store<AppState> store) {
    final state = store.state;
    return CreateCommuteViewModel(
      commute: state.commuteState.commute,
      saveCommute: (Commute commute) => store.dispatch(saveCommuteOp(commute)),
    );
  }
}
