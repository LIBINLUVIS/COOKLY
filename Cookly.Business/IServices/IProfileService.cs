using Cookly.Data.DTOS;

namespace Cookly.Business.IServices;

public interface IProfileService
{
    public Task<ServiceResponseDto<ProfileDto>> GetProfile(int userId, CancellationToken token);
    public Task<ServiceResponseDto<ProfileDto>> UpdatePreferences(int userId, UpdateProfilePreferencesDto request, CancellationToken token);
}
