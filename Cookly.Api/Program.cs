using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Azure.AI.Projects;
using Azure.Identity;
using Cookly.Api.Endpoints;
using Cookly.Business.IServices;
using Cookly.Business.Services;
using Cookly.Data;
using Cookly.Data.DTOS;
using Microsoft.Agents.AI.Workflows;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.AI;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

//config for sql db
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
                       ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

// register the dbcontext into DI Container

builder.Services.AddDbContext<CooklyDbContext>(options =>
{
    options.UseSqlServer(connectionString,
        sqlServerOptionsAction: sqlOptions =>
        {
            // Enables automatic retries for transient SQL errors
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
        });
});

builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("JwtSettings"));

var issuer = builder.Configuration["JwtSettings:Issuer"];
var audience = builder.Configuration["JwtSettings:Audience"];
var signingKey = builder.Configuration["JwtSettings:Key"];

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.MapInboundClaims = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = issuer,
        ValidAudience = audience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey!)),
        ClockSkew = TimeSpan.Zero,
        NameClaimType = JwtRegisteredClaimNames.Name,
    };
});

builder.Services.AddAuthorization();

builder.Services.AddControllers();

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ITokenService, TokenService>();
//agents settings
builder.Services.AddSingleton(sp =>
{
    var endpoint = builder.Configuration["AzureAIFoundry:Endpoint"]!;
    var deploymentName = builder.Configuration["AzureAIFoundry:DeploymentName"]!;
#pragma warning disable OPENAI001
    return new AIProjectClient(new Uri(endpoint), new DefaultAzureCredential())
        .GetProjectOpenAIClient()
        .GetProjectResponsesClient()
        .AsIChatClient(deploymentName);
#pragma warning restore OPENAI001
});

// In-memory checkpointing — singleton so start/respond share the same store
builder.Services.AddSingleton(CheckpointManager.CreateInMemory());
builder.Services.AddSingleton<IRunStateStore, InMemoryRunStateStore>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    
    // Renders the interactive Scalar UI dashboard at /scalar/v1
    app.MapScalarApiReference(options =>
    {
        options.WithTitle("My Cookly API v1")
            .WithPreferredScheme("Bearer") // Sets default auth style if needed
            .WithDefaultHttpClient(ScalarTarget.CSharp, ScalarClient.HttpClient); // Generates C# snippets natively
    });

    // Optional: Proactively redirect root URL directly into Scalar
    app.MapGet("/", () => Results.Redirect("/scalar/v1")).ExcludeFromDescription();
}

app.UseAuthentication();
app.UseAuthorization();
app.UseHttpsRedirection();

app.MapControllers();

app.MapAuthEndpoints();

app.Run();

