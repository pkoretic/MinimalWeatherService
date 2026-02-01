using WeatherApp.Service;
using WeatherApp.Options;
using Microsoft.Extensions.Caching.Hybrid;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpClient<IWeatherService, WeatherService>();
builder.Services.Configure<WeatherOptions>(builder.Configuration.GetSection(WeatherOptions.SectionName));

// use hybrid caching which can be in-memory + distributed (e.g., Redis) if configured
builder.Services.AddHybridCache();

var app = builder.Build();

// Define the endpoint: GET /weather/London
app.MapGet("/weather/{city}", async (string city, IWeatherService weatherService, HybridCache memoryCache, ILogger<WeatherService> logger) =>
{
    var result = await weatherService.GetCurrentWeatherAsync(city);

    // Returns a 200 OK with the JSON string
    return TypedResults.Ok(result);
})
.WithName("GetWeather");

app.Run();
