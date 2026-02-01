namespace WeatherApp.Model;
public record WeatherResponse(
    string City,
    double Temperature,
    string Country
);