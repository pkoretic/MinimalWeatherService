using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace MinimalWeatherService.Tests;

public class AppFactory: WebApplicationFactory<Program>
{
    
}

public class IntegrationTest1: IClassFixture<AppFactory>
{
    private readonly HttpClient _client;

    public IntegrationTest1(AppFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TestLondon()
    {
        var response = await _client.GetAsync("/weather/London");
        // read content as json
        var weatherData = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();

        // assert that London is returned with a number temperature
        Assert.NotNull(weatherData);
        Assert.True(weatherData.ContainsKey("temperature"));
        Assert.True(weatherData.ContainsKey("city"));

        // assert that city is London (asked for London)
        var city = ((JsonElement)weatherData["city"]).GetString();
        Assert.Equal("London", city);

        // assert that temperature is a number
        var temperature = ((JsonElement)weatherData["temperature"]).GetDouble();
        Assert.IsType<double>(temperature);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
