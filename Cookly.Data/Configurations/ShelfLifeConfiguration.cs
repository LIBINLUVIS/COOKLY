using Cookly.Data.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cookly.Data.Configurations;

public class ShelfLifeConfiguration : IEntityTypeConfiguration<ShelfLife>
{
    public void Configure(EntityTypeBuilder<ShelfLife> builder)
    {
        builder.ToTable("ShelfLives");
        builder.HasKey(p => p.ShelfLifeId);

        builder.Property(p => p.NormalizedName).HasMaxLength(150).IsRequired();
        builder.Property(p => p.DisplayName).HasMaxLength(150).IsRequired();
        builder.Property(p => p.Source).HasMaxLength(20).IsRequired();

        builder.HasIndex(p => p.NormalizedName).IsUnique();
    }
}
