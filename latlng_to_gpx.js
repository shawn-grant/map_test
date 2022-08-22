const moment = require ('./moment')

let message = '[LatLng(latitude:18.016059, longitude:-76.743714), LatLng(latitude:18.016186, longitude:-76.743917), LatLng(latitude:18.016291, longitude:-76.743994), LatLng(latitude:18.016373, longitude:-76.743934), LatLng(latitude:18.016576, longitude:-76.743888), LatLng(latitude:18.016916, longitude:-76.743898), LatLng(latitude:18.016973, longitude:-76.743986), LatLng(latitude:18.017048, longitude:-76.743994), LatLng(latitude:18.017086, longitude:-76.744162), LatLng(latitude:18.017389, longitude:-76.744843), LatLng(latitude:18.017951, longitude:-76.744609), LatLng(latitude:18.017947, longitude:-76.744287), LatLng(latitude:18.018094, longitude:-76.744096)]' // Try edit me

message = message.replaceAll('LatLng(', '\n{')
message = message.replaceAll(')', '}')
message = message.replaceAll('latitude', '"latitude"')
message = message.replaceAll('longitude', '"longitude"')

let obj = JSON.parse(message)
// console.log(obj)

var today = moment();
var dateN = moment(today)

obj.forEach((point, i) => {
  let date = dateN.add(5, 'minutes');
  // let date = new Date(now.getTime() + 6 * 60000);
  
  let gpx = `<trkpt lat="${point.latitude}" lon="${point.longitude}">
    <ele>${i}</ele>
    <time>${date.toISOString()}</time>
</trkpt>`

  console.log(gpx)
})
// Log to console