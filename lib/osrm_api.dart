import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ApiOSRM{
  /// It takes the coordinates of the starting point and the destination point and returns a list of
  /// LatLng points that make up the route
  Future<List<LatLng>?> getpoints(String longini,String latini,String longend,String latend) async {
    List<LatLng> routepoints = [];
    var url = Uri.parse('https://router.project-osrm.org/route/v1/driving/$longini,$latini;$longend,$latend?geometries=geojson');
    var response = await http.get(url);

    if(response.statusCode == 200){
      var rutar = jsonDecode(response.body)["routes"][0]["geometry"]["coordinates"];

      // reformat the response to a format where we can get the 
      // latitude and longitude for each point in the route
      for(int i = 0; i < rutar.length; i++) {
        var reep = rutar[i].toString();
        reep = reep.replaceAll("[", "");
        reep = reep.replaceAll("]", "");
        var lat1 = reep.split(',');
        var long1 = reep.split(',');

        // add the coordinates to the route
        routepoints.add(LatLng(double.parse(lat1[1]), double.parse(long1[0])));
      }

      // return the results
      return routepoints;
    } else{
      // return null if the request failed
      return null;
    }
  }
}