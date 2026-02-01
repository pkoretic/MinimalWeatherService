using Microsoft.Extensions.Options;
using WeatherApp.Options;
using WeatherApp.Model;
using Microsoft.Extensions.Caching.Hybrid;

namespace WeatherApp.Service;
public interface IWeatherService
{
    Task<WeatherResponse> GetCurrentWeatherAsync(string city, CancellationToken cancellationToken = default);
}

public class WeatherService(HttpClient httpClient, HybridCache memoryCache, IOptions<WeatherOptions> options, ILogger<WeatherService> logger): IWeatherService
{
    private readonly string _apiKey = options.Value.ApiKey;
    private readonly string _baseUrl = options.Value.BaseUrl;

    public async Task<WeatherResponse> GetCurrentWeatherAsync(string city, CancellationToken token = default)
    {
        var cityKey = city.Trim().ToLowerInvariant();
        var url = $"{_baseUrl}?key={_apiKey}&q={Uri.EscapeDataString(cityKey)}&aqi=no";

        var cacheOptions = new HybridCacheEntryOptions
        {
            Expiration = TimeSpan.FromMinutes(3)
        };

        // Get from cache or fetch new data
        var externalWeatherResponse = await memoryCache.GetOrCreateAsync(
            cityKey,
            async cancellationToken =>
            {
                logger.LogInformation("Cache MISS for {City}, fetching new data", city);
                return await httpClient.GetFromJsonAsync<ExternalWeatherApiResponse>(url, cancellationToken);
            },
            options: cacheOptions,
            cancellationToken: token
        );

        logger.LogDebug($"External weather response: {externalWeatherResponse}");

        return new WeatherResponse(
            City:  externalWeatherResponse?.Location?.Name ?? city,
            Country: externalWeatherResponse?.Location?.Country ?? "",
            Temperature: externalWeatherResponse?.Current?.Temperature ?? 0
        );
    }
}

