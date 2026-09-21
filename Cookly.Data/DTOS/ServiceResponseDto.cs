namespace Cookly.Data.DTOS;

public class ServiceResponseDto<T>
{
    public T Data { get; set; }
    public bool Success { get; set; }
    public string? MessageKey { get; set; }
    public string? Message { get; set; }
    
}