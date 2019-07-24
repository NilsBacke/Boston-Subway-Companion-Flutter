import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:location/location.dart';
import 'package:mbta_companion/src/models/stop.dart';
import 'package:mbta_companion/src/screens/CommuteScreen/utils/stop_distance.dart';
import 'package:mbta_companion/src/screens/CommuteScreen/widgets/three_part_card.dart';
import 'package:mbta_companion/src/services/mbta_service.dart';
import 'package:mbta_companion/src/services/permission_service.dart';
import 'package:mbta_companion/src/state/operations/locationOperations.dart';
import 'package:mbta_companion/src/state/operations/nearestStopOperations.dart';
import 'package:mbta_companion/src/state/state.dart';
import 'package:mbta_companion/src/utils/navigation_utils.dart';
import 'package:mbta_companion/src/widgets/stop_details_tile.dart';
import 'package:redux/redux.dart';

class NearestStopCard extends StatefulWidget {
  @override
  _NearestStopCardState createState() => _NearestStopCardState();
}

class _NearestStopCardState extends State<NearestStopCard> {
  @override
  void initState() {
    super.initState();
    // final store = StoreProvider.of<AppState>(context);
    // final viewModel = _NearestStopViewModel.create(store);

    // if (viewModel.location == null && !viewModel.isLocationLoading) {
    //   viewModel.getLocation();
    // }

    // if (viewModel.nearestStop == null &&
    //     !viewModel.isNearestStopLoading &&
    //     viewModel.location != null) {
    //   viewModel.getNearestStop(viewModel.location);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _NearestStopViewModel>(
      converter: (store) => _NearestStopViewModel.create(store),
      builder: (context, viewModel) {
        if (viewModel.location == null &&
            !viewModel.isLocationLoading &&
            viewModel.locationErrorStatus != null) {
          viewModel.getLocation();
        }

        if (viewModel.nearestStop == null &&
            !viewModel.isNearestStopLoading &&
            viewModel.nearestStopErrorMessage != '' &&
            viewModel.location != null) {
          viewModel.getNearestStop(viewModel.location);
        }

        if (viewModel.isLocationLoading || viewModel.isNearestStopLoading) {
          return nearestStopLoadingIndicator();
        }
        if (viewModel.locationErrorStatus == LocationStatus.noPermission) {
          return locationPermissionsNotEnabled(context);
        }
        if (viewModel.locationErrorStatus == LocationStatus.noService) {
          return locationServicesNotEnabled(context);
        }
        return nearestStopCard(context, viewModel);
      },
    );
  }

  Widget nearestStopLoadingIndicator() {
    return blankNearestStopCard(
      child: CircularProgressIndicator(
        semanticsLabel: "Loading closest stop",
      ),
    );
  }

  Widget locationPermissionsNotEnabled(context) {
    return blankNearestStopCard(
      child: Text(
        'Location permissions are required to view the nearest stop and distances to stops\n\nGo to settings to enable permissions',
        style: Theme.of(context).textTheme.body2,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget locationServicesNotEnabled(context) {
    return blankNearestStopCard(
      child: Text(
        'Location services are not enabled',
        style: Theme.of(context).textTheme.body2,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget blankNearestStopCard({child: Widget}) {
    return Container(
      height: 200.0,
      padding: EdgeInsets.all(2.0),
      child: Card(
        child: Center(child: child == null ? Container() : child),
      ),
    );
  }

  nearestStopCard(context, _NearestStopViewModel viewModel) {
    if (viewModel.nearestStop.length == 0) {
      return blankNearestStopCard(
        child: Text(
          'No stops within ${MBTAService.rangeInMiles} miles',
          style: Theme.of(context).textTheme.body2,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ThreePartCard(
      'Nearest Stop',
      GestureDetector(
        onTap: () {
          showDetailForStop(context, viewModel.nearestStop[0]);
        },
        child: Card(
          elevation: 0.0,
          child: VariablePartTile(
            viewModel.nearestStop[0].id,
            title: viewModel.nearestStop[0].name,
            subtitle1: viewModel.nearestStop[0].lineName,
            otherInfo: [viewModel.nearestStop[0].directionDescription],
            lineInitials: viewModel.nearestStop[0].lineInitials,
            lineColor: viewModel.nearestStop[0].lineColor,
            onTap: () {
              showDetailForStop(context, viewModel.nearestStop[0]);
            },
          ),
        ),
      ),
      GestureDetector(
        onTap: () {
          showDetailForStop(context, viewModel.nearestStop[1]);
        },
        child: Card(
          elevation: 0.0,
          child: VariablePartTile(
            viewModel.nearestStop[1].id,
            title: viewModel.nearestStop[1].name,
            subtitle1: viewModel.nearestStop[1].lineName,
            otherInfo: [viewModel.nearestStop[1].directionDescription],
            lineInitials: viewModel.nearestStop[1].lineInitials,
            lineColor: viewModel.nearestStop[1].lineColor,
            onTap: () {
              showDetailForStop(context, viewModel.nearestStop[1]);
            },
          ),
        ),
      ),
      trailing: Text(
        viewModel.location != null
            ? '${getDistanceFromNearestStop(viewModel.location, viewModel.nearestStop)} mi'
            : '---',
        style: Theme.of(context).textTheme.body2,
      ),
    );
  }
}

class _NearestStopViewModel {
  final LocationData location;
  final bool isLocationLoading;
  final LocationStatus locationErrorStatus;
  final List<Stop> nearestStop;
  final bool isNearestStopLoading;
  final String nearestStopErrorMessage;

  final Function() getLocation;
  final Function(LocationData) getNearestStop;

  _NearestStopViewModel({
    this.location,
    this.isLocationLoading,
    this.locationErrorStatus,
    this.nearestStop,
    this.isNearestStopLoading,
    this.nearestStopErrorMessage,
    this.getLocation,
    this.getNearestStop,
  });

  factory _NearestStopViewModel.create(Store<AppState> store) {
    final state = store.state;
    return _NearestStopViewModel(
      location: state.locationState.locationData,
      isLocationLoading: state.locationState.isLocationLoading,
      locationErrorStatus: state.locationState.locationErrorStatus,
      nearestStop: state.nearestStopState.nearestStop,
      isNearestStopLoading: state.nearestStopState.isNearestStopLoading,
      nearestStopErrorMessage: state.nearestStopState.nearestStopErrorMessage,
      getLocation: () => store.dispatch(fetchLocation()),
      getNearestStop: (LocationData locationData) =>
          store.dispatch(fetchNearestStop(locationData)),
    );
  }
}