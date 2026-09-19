using COOKLY.Data.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace COOKLY.Data.Configurations;

public class DishConfiguration:IEntityTypeConfiguration<Dish>
{
    public void Configure(EntityTypeBuilder<Dish> builder)
    {
        builder.ToTable("Dishes");
        //PK
        builder.HasKey(p => p.DishId);
        builder.Property(p => p.Name).IsRequired().HasMaxLength(150);
        builder.Property(p => p.Goal).HasMaxLength(250);

        builder.HasOne(p => p.Profile)
            .WithMany(p => p.Dishes)
            .HasForeignKey(o => o.ProfileId);

        builder.HasMany(p => p.Ingredients)
            .WithOne(p => p.Dish)
            .HasForeignKey(o => o.DishId);
        
        builder.HasMany(p => p.Instructions)
            .WithOne(p => p.Dish)
            .HasForeignKey(o => o.DishId);

        builder.HasIndex(p => p.Name).IsUnique();
    }
}

public class IngredientConfiguration:IEntityTypeConfiguration<Ingredient>
{
    public void Configure(EntityTypeBuilder<Ingredient> builder)
    {
        builder.ToTable("Ingredients");
        //PK
        builder.HasKey(p => p.IngredientId);
        builder.Property(p => p.Name).HasMaxLength(150);
        builder.Property(p => p.Quantity).HasMaxLength(150);

        builder.HasOne(p => p.Dish)
            .WithMany(p => p.Ingredients)
            .HasForeignKey(o => o.DishId);
    }
}

public class InstructionConfiguration:IEntityTypeConfiguration<Instruction>
{
    public void Configure(EntityTypeBuilder<Instruction> builder)
    {
        builder.ToTable("Instructions");
        //PK
        builder.HasKey(p => p.InstructionId);
        builder.Property(p => p.Preparation).HasMaxLength(150);
        
        builder.HasOne(p => p.Dish)
            .WithMany(p => p.Instructions)
            .HasForeignKey(o => o.DishId);
    }
}