# https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/docker/building-net-docker-images?view=aspnetcore-10.0
# image can also be built using dotnet publish /t:PublishContainer

# build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# copy csproj and restore as distinct layers
COPY . ./
RUN dotnet restore

# copy everything else and build
COPY . .
RUN dotnet publish -o /out --no-restore

# final stage/image
FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS final
WORKDIR /app
COPY --from=build /out .
EXPOSE 8080
ENTRYPOINT ["dotnet", "MinimalWeatherService.dll"]
