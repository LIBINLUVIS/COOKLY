using Cookly.Data.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cookly.Data.Configurations;

public class InventoryConfiguration:IEntityTypeConfiguration<Inventory>
{
    public void Configure(EntityTypeBuilder<Inventory> builder)
    {
        builder.ToTable("Inventories");
        //PK
        builder.HasKey(p => p.InventoryId);

        builder.HasOne(p => p.User)
            .WithOne(p => p.Inventory)
            .HasForeignKey<Inventory>(p => p.UserId);

        builder.HasMany(p => p.Items)
            .WithOne(p => p.Inventory)
            .HasForeignKey(o => o.InventoryId);
    }
}

public class ItemConfiguration:IEntityTypeConfiguration<Item>
{
    public void Configure(EntityTypeBuilder<Item> builder)
    {
        builder.ToTable("Items");
        //PK
        builder.HasKey(p => p.ItemId);

        builder.Property(p => p.Name).HasMaxLength(150);
        builder.Property(p => p.Unit).HasMaxLength(100);

        builder.HasOne(p => p.Inventory)
            .WithMany(p => p.Items)
            .HasForeignKey(o => o.InventoryId);

    }
}