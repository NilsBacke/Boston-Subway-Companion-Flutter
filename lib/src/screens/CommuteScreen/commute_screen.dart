import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:mbta_companion/src/models/commute.dart';
import 'package:mbta_companion/src/screens/CommuteScreen/widgets/nearest_stop_card.dart';
import 'package:mbta_companion/src/screens/CommuteScreen/widgets/three_part_card.dart';
import 'package:mbta_companion/src/state/operations/commuteOperations.dart';
import 'package:mbta_companion/src/state/state.dart';
import 'package:mbta_companion/src/utils/navigation_utils.dart';
import 'package:mbta_companion/src/utils/timeofday_helper.dart';
import 'package:mbta_companion/src/widgets/commute_time_circle_combo.dart';
import 'package:redux/redux.dart';
import '../../widgets/stop_details_tile.dart';

class CommuteScreen extends StatefulWidget {
  @override
  _CommuteScreenState createState() => _CommuteScreenState();
}

class _CommuteScreenState extends State<CommuteScreen> {
  @override
  void initState() {
    super.initState();
    // final store = StoreProvider.of<AppState>(context);
    // final viewModel = _CommuteViewModel.create(store);

    // if (viewModel.commute == null && !viewModel.isCommuteLoading) {
    //   viewModel.getCommute();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: <Widget>[
          NearestStopCard(),
          StoreConnector<AppState, _CommuteViewModel>(
            converter: (store) => _CommuteViewModel.create(store),
            builder: (context, _CommuteViewModel viewModel) {
              if (viewModel.commute == null &&
                  !viewModel.isCommuteLoading &&
                  (viewModel.commuteExists == null ||
                      viewModel.commuteExists == true)) {
                viewModel.getCommute();
              }

              if (viewModel.isCommuteLoading) {
                return loadingCommuteCard();
              }
              if (viewModel.commute == null &&
                  viewModel.commuteErrorMessage == '') {
                return emptyCommuteCard(context, viewModel);
              }

              return commuteCard(context, viewModel);
            },
          ),
        ],
      ),
    );
  }

  Widget commuteCard(context, _CommuteViewModel viewModel) {
    return ThreePartCard(
      'Work Commute',
      GestureDetector(
        onTap: () {
          showDetailForStop(context, viewModel.commute.stop1);
        },
        child: Card(
          elevation: 0.0,
          child: VariablePartTile(
            viewModel.commute.stop1.id,
            title: viewModel.commute.stop1.name,
            subtitle1: viewModel.commute.stop1.lineName,
            otherInfo: [viewModel.commute.stop1.directionDescription],
            lineInitials: viewModel.commute.stop1.lineInitials,
            lineColor: viewModel.commute.stop1.lineColor,
            onTap: () {
              showDetailForStop(context, viewModel.commute.stop1);
            },
          ),
        ),
      ),
      GestureDetector(
        onTap: () {
          showDetailForStop(context, viewModel.commute.stop2);
        },
        child: Card(
          elevation: 0.0,
          child: VariablePartTile(
            viewModel.commute.stop2.id,
            title: viewModel.commute.stop2.name,
            subtitle1: viewModel.commute.stop2.lineName,
            otherInfo:
                viewModel.commute.stop2.id == viewModel.commute.workStopId
                    ? [
                        TimeOfDayHelper.convertToString(
                            viewModel.commute.arrivalTime)
                      ]
                    : [],
            lineInitials: viewModel.commute.stop2.lineInitials,
            lineColor: viewModel.commute.stop2.lineColor,
            timeCircles: false,
            trailing: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(bottom: 8.0, top: 4.0, right: 4.0),
                  child: Text('Arrive at:'),
                ),
                CommuteTimeCircleCombo(
                    viewModel.commute.stop1, viewModel.commute.stop2),
              ],
            ),
          ),
        ),
      ),
      trailing: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => editCommute(context, viewModel),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => showDeleteDialog(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget loadingCommuteCard() {
    return Container(
      height: 200.0,
      child: Card(
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: "Loading your commute",
          ),
        ),
      ),
    );
  }

  Widget emptyCommuteCard(context, _CommuteViewModel viewModel) {
    return GestureDetector(
      onTap: () => editCommute(context, viewModel),
      child: Container(
        height: 200.0,
        child: Card(
          child: Center(
            child: Text(
              "Tap here to create a commute",
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> editCommute(context, _CommuteViewModel viewModel) async {
    // Navigator.of(context)
    //     .push(
    //       MaterialPageRoute(
    //         builder: (context) => CreateCommuteScreen(
    //           commute: viewModel.commute,
    //         ),
    //       ),
    //     )
    //     .then((val) => viewModel.getCommute());
  }

  void showDeleteDialog(context, _CommuteViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Are you sure to want to delete this commute?",
            style: Theme.of(context).textTheme.body1,
          ),
          content: Text("This action cannot be undone."),
          actions: <Widget>[
            FlatButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("Delete"),
              onPressed: () async {
                viewModel.deleteCommute(viewModel.commute);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _CommuteViewModel {
  final Commute commute;
  final bool isCommuteLoading;
  final String commuteErrorMessage;
  final bool commuteExists;

  final Function() getCommute;
  final Function(Commute) saveCommute;
  final Function(Commute) deleteCommute;

  _CommuteViewModel(
      {this.commute,
      this.isCommuteLoading,
      this.commuteErrorMessage,
      this.commuteExists,
      this.getCommute,
      this.saveCommute,
      this.deleteCommute});

  factory _CommuteViewModel.create(Store<AppState> store) {
    final state = store.state;
    return _CommuteViewModel(
        commute: state.commuteState.commute,
        isCommuteLoading: state.commuteState.isCommuteLoading,
        commuteErrorMessage: state.commuteState.commuteErrorMessage,
        commuteExists: state.commuteState.doesCommuteExist,
        getCommute: () => store.dispatch(fetchCommute()),
        saveCommute: (Commute commute) =>
            store.dispatch(saveCommuteOp(commute)),
        deleteCommute: (Commute commute) =>
            store.dispatch(deleteCommuteOp(commute)));
  }
}