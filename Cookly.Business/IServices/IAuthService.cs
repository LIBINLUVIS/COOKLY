using Cookly.Data.DTOS;
using Cookly.Data.DTOS.Authentication;

namespace Cookly.Business.IServices;

public interface IAuthService
{
    public Task<ServiceResponseDto<AuthResponseDto>> LoginAsync(AuthRequestDto data,CancellationToken ctk);
}