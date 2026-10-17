using Cookly.Business.IServices;
using Cookly.Business.Services;
using Cookly.Business.Validators;
using Cookly.Data.DTOS;
using Microsoft.AspNetCore.Mvc;

namespace Cookly.Api.Endpoints;

public static class ProfileController
{
    public static IEndpointRouteBuilder MapProfileEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/profile")
            .WithTags("Profile");

        group.MapGet("", GetProfile).RequireAuthorization();
        group.MapPut("/preferences", UpdatePreferences).RequireAuthorization();
        return app;
    }

    private static async Task<IResult> GetProfile(IProfileService _profileService, UserService _user, CancellationToken ctk)
    {
        var result = await _profileService.GetProfile(_user.GetUserId(), ctk);
        return Results.Ok(result);
    }

    private static async Task<IResult> UpdatePreferences([FromBody] UpdateProfilePreferencesDto request,
        IProfileService _profileService, UserService _user, CancellationToken ctk)
    {
        var (isValid, errors) = request.TryValidate();
        if (!isValid)
            return Results.ValidationProblem(errors);

        var result = await _profileService.UpdatePreferences(_user.GetUserId(), request, ctk);
        return Results.Ok(result);
    }
}
