using System.Reflection;
using Cookly.Data.Models;
using Microsoft.EntityFrameworkCore;

namespace Cookly.Data;

public class CooklyDbContext: DbContext
{
    public CooklyDbContext(DbContextOptions<CooklyDbContext> options) : base(options)
    { }
    
    public DbSet<Dish> Dishes { get; set; }
    public DbSet<Ingredient> Ingredients { get; set; }
    public DbSet<Instruction> Instructions { get; set; }
    public DbSet<Inventory> Inventories { get; set; }
    public DbSet<Item> Items { get; set; }
    public DbSet<Profile> Profiles { get; set; }
    public DbSet<User> Users { get; set; }
    public DbSet<ShelfLife> ShelfLives { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
    
    
}