using Cookly.Business.IServices;
using Cookly.Data.DTOS.Authentication;
using Cookly.Data.Models;
using Microsoft.AspNetCore.Mvc;

namespace Cookly.Api.Endpoints;

public static class AuthController
{
    
    //extension method to map all related endpoints
    public static IEndpointRouteBuilder MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth")
            .WithTags("Authentication");

        // define all the endpoints inside this api/Auth route

        group.MapPost("/login", Login);
        return app;
    }

    private static async Task<IResult> Login([FromBody] AuthRequestDto request,IAuthService authService,CancellationToken ctk)
    {
        var result = await authService.LoginAsync(request,ctk);
        return Results.Ok(result);
    }
}