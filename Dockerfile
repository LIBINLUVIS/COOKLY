FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["COOKLY.sln", "./"]
COPY ["Cookly.Api/Cookly.Api.csproj", "Cookly.Api/"]
COPY ["Cookly.Agents/Cookly.Agents.csproj", "Cookly.Agents/"]
COPY ["Cookly.Business/Cookly.Business.csproj", "Cookly.Business/"]
COPY ["Cookly.Data/Cookly.Data.csproj", "Cookly.Data/"]
RUN dotnet restore "COOKLY.sln"
COPY . .
WORKDIR "/src/Cookly.Api"
RUN dotnet build "./Cookly.Api.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./Cookly.Api.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Cookly.Api.dll"]
