using System.ComponentModel.DataAnnotations;

namespace Cookly.Business.Validators;

public static class ValidationExtensions
{
    public static (bool IsValid, Dictionary<string, string[]> Errors) TryValidate<T>(this T dto) where T : class
    {
        var validationContext = new ValidationContext(dto, serviceProvider: null, items: null);
        var validationResults = new List<ValidationResult>();

        // Set validateAllProperties to true to validate attributes beyond just [Required]
        bool isValid = Validator.TryValidateObject(dto, validationContext, validationResults, validateAllProperties: true);

        if (isValid)
        {
            return (true, new Dictionary<string, string[]>());
        }

        // Group errors by property name
        var errors = validationResults
            .SelectMany(result => result.MemberNames.Select(memberName => new { memberName, result.ErrorMessage }))
            .GroupBy(x => x.memberName)
            .ToDictionary(
                g => g.Key,
                g => g.Select(x => x.ErrorMessage ?? "Invalid value.").ToArray()
            );

        return (false, errors);
    }
}