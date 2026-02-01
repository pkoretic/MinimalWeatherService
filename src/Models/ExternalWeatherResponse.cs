using System.Text.Json.Serialization;

namespace WeatherApp.Model;
internal record ExternalWeatherApiResponse(
    [property: JsonPropertyName("location")] LocationData Location,
    [property: JsonPropertyName("current")] TemperatureData Current
);

internal record LocationData(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("country")] string Country
);

internal record TemperatureData(
    [property: JsonPropertyName("temp_c")] double Temperature
);
