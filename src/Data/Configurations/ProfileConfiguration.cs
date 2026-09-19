using COOKLY.Data.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace COOKLY.Data.Configurations;

public class ProfileConfiguration:IEntityTypeConfiguration<Profile>
{
    public void Configure(EntityTypeBuilder<Profile> builder)
    {
        builder.ToTable("Profiles");
        //PK
        builder.HasKey(p => p.ProfileId);

        builder.Property(p => p.Goal).HasMaxLength(350);
        builder.Property(p => p.Preference).HasMaxLength(350);
        builder.Property(p => p.Progress).HasMaxLength(350);

        builder.HasOne(p => p.User)
            .WithOne(p => p.Profile)
            .HasForeignKey<Profile>(o => o.UserId);

        builder.HasMany(p => p.Dishes)
            .WithOne(p => p.Profile)
            .HasForeignKey(o => o.ProfileId);

    }
}


public class UserConfiguration:IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");
        //PK
        builder.HasKey(p => p.UserId);
        
        builder.Property(p => p.Email).IsRequired().HasMaxLength(100);
        builder.Property(p => p.FirstName).HasMaxLength(100);
        builder.Property(p => p.LastName).HasMaxLength(100);
        builder.Property(p => p.DisplayName).HasMaxLength(100);

        builder.HasOne(p => p.Profile)
            .WithOne(p => p.User)
            .HasForeignKey<Profile>(o => o.UserId);

        builder.HasOne(p => p.Inventory)
            .WithOne(p => p.User)
            .HasForeignKey<Inventory>(o => o.UserId);
    }
}