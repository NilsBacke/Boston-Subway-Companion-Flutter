import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:location/location.dart';
import 'package:mbta_companion/src/models/stop.dart';
import 'package:mbta_companion/src/screens/ExploreScreen/utils/filter_search_results.dart';
import 'package:mbta_companion/src/services/permission_service.dart';
import 'package:mbta_companion/src/state/operations/allStopsOperations.dart';
import 'package:mbta_companion/src/state/operations/locationOperations.dart';
import 'package:mbta_companion/src/state/state.dart';
import 'package:mbta_companion/src/widgets/stops_list_view.dart';
import 'package:redux/redux.dart';

const locationPermissionText =
    'Location permissions are required to view the nearest stop and distances to stops\n\nGo to settings to enable permissions';
const locationServicesText = 'Location services are not enabled';

class ExploreScreen extends StatefulWidget {
  final Function(Stop) onTap;
  final String topMessage;
  final bool timeCircles;

  ExploreScreen({this.onTap, this.topMessage, this.timeCircles = true});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  TextEditingController searchBarController = TextEditingController();
  List<Stop> filteredStops = [];

  Widget getBodyWidget(_ExploreViewModel viewModel) {
    // error handling
    if (viewModel.locationErrorStatus != null) {
      if (viewModel.locationErrorStatus == LocationStatus.noPermission) {
        return errorTextWidget(text: locationPermissionText);
      }

      if (viewModel.locationErrorStatus == LocationStatus.noService) {
        return errorTextWidget(text: locationServicesText);
      }
    }

    if (viewModel.allStopsErrorMessage.isNotEmpty) {
      return errorTextWidget(text: viewModel.allStopsErrorMessage);
    }

    // loading
    if (viewModel.isAllStopsLoading || viewModel.isLocationLoading) {
      return StopsLoadingIndicator();
    }

    if (filteredStops == null || filteredStops.length == 0) {
      this.filteredStops = viewModel.allStops;
    }

    if (filteredStops.length == 0 && viewModel.allStops.length != 0) {
      return errorTextWidget();
    }

    return StopsListView(filteredStops,
        onTap: widget.onTap, timeCircles: widget.timeCircles);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StoreConnector<AppState, _ExploreViewModel>(
        converter: (store) => _ExploreViewModel.create(store),
        builder: (context, _ExploreViewModel viewModel) {
          var bodyWidget = getBodyWidget(viewModel);

          if (viewModel.location == null &&
              !viewModel.isLocationLoading &&
              viewModel.locationErrorStatus == null) {
            viewModel.getLocation();
          }

          if (viewModel.allStops != null &&
              viewModel.allStops.length == 0 &&
              !viewModel.isAllStopsLoading &&
              viewModel.allStopsErrorMessage.isEmpty &&
              viewModel.location != null) {
            viewModel.getAllStops(viewModel.location);
          }

          return Column(
            children: <Widget>[
              widget.topMessage == null
                  ? Container()
                  : Container(
                      padding: EdgeInsets.all(10.0),
                      child: Text(
                        widget.topMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.caption,
                      ),
                    ),
              Container(
                  padding: EdgeInsets.all(12.0),
                  child: TextField(
                      controller: searchBarController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(25.0),
                          ),
                        ),
                      ),
                      onChanged: (searchText) {
                        this.setState(() {
                          this.filteredStops = filterSearchResults(
                              searchText, viewModel.allStops, this.mounted);
                        });
                      })),
              Expanded(child: bodyWidget),
            ],
          );
        },
      ),
    );
  }

  Widget errorTextWidget({String text}) {
    return Container(
      child: Center(
        child: Text(
          text ?? "No stops found\nTry searching something else",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.body2,
        ),
      ),
    );
  }
}

class _ExploreViewModel {
  final LocationData location;
  final bool isLocationLoading;
  final LocationStatus locationErrorStatus;
  final List<Stop> allStops;
  final bool isAllStopsLoading;
  final String allStopsErrorMessage;

  final Function() getLocation;
  final Function(LocationData) getAllStops;

  _ExploreViewModel(
      {this.location,
      this.isLocationLoading,
      this.locationErrorStatus,
      this.allStops,
      this.isAllStopsLoading,
      this.allStopsErrorMessage,
      this.getLocation,
      this.getAllStops});

  factory _ExploreViewModel.create(Store<AppState> store) {
    final state = store.state;
    return _ExploreViewModel(
        location: state.locationState.locationData,
        isLocationLoading: state.locationState.isLocationLoading,
        locationErrorStatus: state.locationState.locationErrorStatus,
        allStops: state.allStopsState.allStops,
        isAllStopsLoading: state.allStopsState.isAllStopsLoading,
        allStopsErrorMessage: state.allStopsState.allStopsErrorMessage,
        getLocation: () => store.dispatch(fetchLocation()),
        getAllStops: (LocationData locationData) =>
            store.dispatch(fetchAllStops(locationData)));
  }
}
