#include <array>
#include <algorithm>
#include <cctype>
#include <exception>
#include <iostream>
#include <sstream>
#include <string>

#include "lodepng/lodepng.h"

struct coord_t
{
    int x;
    int y;
};

struct dimen_t
{
    int w;
    int h;
};

bool in_bounds(coord_t crd, dimen_t bounds)
{
    return crd.x >= 0 && crd.y >= 0 && crd.x < bounds.w && crd.y < bounds.h;
}

template<typename T, int Width, int Height>
class fixed_grid
{
private:
    using array_type = std::array<T, Width*Height>;
public:
    using is_grid = void;
    using value_type = T;
    using iterator = typename array_type::iterator;
    using const_iterator = typename array_type::const_iterator;

    fixed_grid() = default;
    fixed_grid(T const& value)
    {
        for(T& t : m_arr)
            t = value;
    }

    fixed_grid(fixed_grid const&) = default;
    fixed_grid(fixed_grid&&) = default;

    fixed_grid& operator=(fixed_grid const&) = default;
    fixed_grid& operator=(fixed_grid&&) = default;
    
    bool operator==(fixed_grid const& o) const
    {
        return m_arr == o.m_arr;
    }

    bool operator!=(fixed_grid const& o) const
    {
        return m_arr != o.m_arr;
    }

    const_iterator cbegin() const { return m_arr.begin(); }
    const_iterator cend() const { return m_arr.end(); }

    const_iterator begin() const { return cbegin(); }
    const_iterator end() const { return cend(); }

    iterator begin() { return m_arr.begin(); }
    iterator end() { return m_arr.end(); }

    constexpr dimen_t dimensions() const { return { Width, Height }; }

    T const& at(coord_t c) const { return m_arr.at(index(c)); }
    T& at(coord_t c) { return m_arr.at(index(c)); }

    T const& operator[](coord_t c) const { return m_arr[index(c)]; }
    T& operator[](coord_t c) { return m_arr[index(c)]; }

    T const* data() const { return m_arr.data(); }
    T* data() { return m_arr.data(); }

    std::size_t size() const { return m_arr.size(); }

private:
    std::size_t index(coord_t c) const { return c.y * dimensions().w + c.x; }

    array_type m_arr;
};

using pixels_t = fixed_grid<int, 256, 240>;
using tiles_t = fixed_grid<int, 256/8, 240/8>;
using pattern_t = fixed_grid<int, 8, 8>;

pixels_t find_zones(pixels_t in)
{
    std::vector<coord_t> next;
    pixels_t zones(0);
    int zone_n = 0;

    while(true)
    {
        ++zone_n;
        //std::printf("%i\n", zone_n);

        for(int y = 0; y != in.dimensions().h; ++y)
        for(int x = 0; x != in.dimensions().w; ++x)
        {
            if(zones[{x, y}] == 0 && in[{x, y}])
            {
                next.push_back({x, y});
                zones[{x, y}] = zone_n;
                goto found_new_zone;
            }
        }
        return zones;
    found_new_zone:

        while(!next.empty())
        {
            coord_t eval = next.back();
            next.pop_back();

            coord_t crd = coord_t{ eval.x - 1, eval.y };
            if(in_bounds(crd, in.dimensions()) && in[crd] && !zones[crd])
            {
                next.push_back(crd);
                zones[crd] = zone_n;
            }

            crd = coord_t{ eval.x + 1, eval.y };
            if(in_bounds(crd, in.dimensions()) && in[crd] && !zones[crd])
            {
                next.push_back(crd);
                zones[crd] = zone_n;
            }

            crd = coord_t{ eval.x, eval.y - 1 };
            if(in_bounds(crd, in.dimensions()) && in[crd] && !zones[crd])
            {
                next.push_back(crd);
                zones[crd] = zone_n;
            }

            crd = coord_t{ eval.x, eval.y + 1 };
            if(in_bounds(crd, in.dimensions()) && in[crd] && !zones[crd])
            {
                next.push_back(crd);
                zones[crd] = zone_n;
            }
        }
    }
}

pixels_t combine_zones(pixels_t rz, pixels_t gz, pixels_t bz)
{
    pixels_t ret;
    for(int y = 0; y != ret.dimensions().h; ++y)
    for(int x = 0; x != ret.dimensions().w; ++x)
    {
        int new_zone = 0;
        if(rz[{x, y}])
            new_zone = rz[{x, y}] + 64;
        if(gz[{x, y}])
            new_zone = gz[{x, y}] + 128;
        if(bz[{x, y}])
            new_zone = bz[{x, y}] + 192;
        ret[{x, y}] = new_zone;
    }
    return ret;
}

struct find_patterns_results_t
{
    std::array<std::vector<pattern_t>, 2> patterns;
    tiles_t indices;
};

find_patterns_results_t find_patterns(pixels_t cz)
{
    find_patterns_results_t ret;
    
    for(int m = 0; m != 2; ++m)
    for(int yt = m*15; yt != m*15+15; ++yt)
    for(int xt = 0; xt != ret.indices.dimensions().w; ++xt)
    {
        pattern_t pattern;
        for(int y = 0; y != 8; ++y)
        for(int x = 0; x != 8; ++x)
            pattern[{x, y}] = cz[{ xt*8 + x, yt*8 + y }];

        std::size_t i = 0;
        for(; i != ret.patterns[m].size(); ++i)
        {
            if(ret.patterns[m][i] == pattern)
                break;
        }
        if(i == ret.patterns[m].size())
            ret.patterns[m].push_back(pattern);
        ret.indices[{xt, yt}] = i;
    }
    std::printf("%lu\n", ret.patterns[0].size());
    std::printf("%lu\n", ret.patterns[1].size());
    return ret;
}

void write_pattern(pattern_t pattern, FILE* fp)
{
    for(int b = 0; b != 2; ++b)
    for(int y = 0; y != 8; ++y)
    {
        unsigned char byte = 0;
        for(int x = 0; x != 8; ++x)
        {
            int color = pattern[{x, y}] / 64;
            if(color == 1+b || color == 3)
                byte |= (0x80 >> x);
        }
        std::fputc(byte, fp);
    }
}

tiles_t find_neighbors(pixels_t zones)
{
    tiles_t tzones(0);
    for(int yt = 0; yt != tzones.dimensions().h; ++yt)
    for(int xt = 0; xt != tzones.dimensions().w; ++xt)
    {
        int z = 0;
        for(int y = 0; y != 8; ++y)
        for(int x = 0; x != 8; ++x)
        {
            coord_t c = { xt*8 + x, yt*8 + y };
            if(z == 0)
                z = zones[c];
            else if(zones[c] != z && zones[c] != 0)
            {
                std::printf("%i, %i [%i, %i]\n", c.x, c.y, z, zones[c]);
                throw 0;
            }
        }
        tzones[{xt, yt}] = z;
    }

    tiles_t ret(0);

    for(int yt = 0; yt != tzones.dimensions().h; ++yt)
    for(int xt = 0; xt != tzones.dimensions().w; ++xt)
    {
        coord_t crd = { xt + 1, yt };
        bool right = (in_bounds(crd, tzones.dimensions()) 
                      && tzones[{xt, yt}] == tzones[crd]);
        crd = { xt - 1, yt };
        bool left = (in_bounds(crd, tzones.dimensions()) 
                     && tzones[{xt, yt}] == tzones[crd]);
        crd = { xt, yt + 1 };
        bool down = (in_bounds(crd, tzones.dimensions()) 
                     && tzones[{xt, yt}] == tzones[crd]);
        crd = { xt, yt - 1 };
        bool up = (in_bounds(crd, tzones.dimensions()) 
                   && tzones[{xt, yt}] == tzones[crd]);

        if(right)
            ret[{xt,yt}] |= 1 << 0;
        if(left)
            ret[{xt,yt}] |= 1 << 1;
        if(down)
            ret[{xt,yt}] |= 1 << 2;
        if(up)
            ret[{xt,yt}] |= 1 << 3;
    }

    return ret;
}

int main(int argc, char** argv) 
{
    if(argc != 2) 
    {
        std::fprintf(stderr, 
                     "usage: %s [image in]\n",
                     argv[0]);
        return EXIT_FAILURE;
    }
    std::string image_in_filename = argv[1];

    std::vector<unsigned char> image_in;
    unsigned width;
    unsigned height;
    unsigned error = lodepng::decode(image_in, width, height,
                                     image_in_filename);
    if(error)
    {
        std::fprintf(stderr, "decoder error [%i]: %s\n",
                     error, lodepng_error_text(error));
        return EXIT_FAILURE;
    }

    if(width != 256 || height != 240)
    {
        std::fprintf(stderr, "bad image size");
        return EXIT_FAILURE;
    }

    pixels_t r(0);
    pixels_t g(0);
    pixels_t b(0);
    pixels_t black(0);

    for(int y = 0; y != (int)height; ++y)
    for(int x = 0; x != (int)width;  ++x)
    {
        if(image_in[(y*width + x)*4 + 0] == 255)
            r[{x, y}] = true;
        else if(image_in[(y*width + x)*4 + 1] == 255)
            g[{x, y}] = true;
        else if(image_in[(y*width + x)*4 + 2] == 255)
            b[{x, y}] = true;
        else
            black[{x, y}] = true;
    }

    pixels_t rz = find_zones(r);
    pixels_t gz = find_zones(g);
    pixels_t bz = find_zones(b);

    tiles_t rn = find_neighbors(rz);
    tiles_t gn = find_neighbors(gz);
    tiles_t bn = find_neighbors(bz);

    pixels_t cz = combine_zones(rz, gz, bz);
    auto result = find_patterns(cz);

    FILE* pat1 = std::fopen("pat1.bin", "wb");
    FILE* pat2 = std::fopen("pat2.bin", "wb");
    FILE* nt = std::fopen("nt.bin", "wb");
    FILE* nbor_r = std::fopen("nbor_r.bin", "wb");
    FILE* nbor_g = std::fopen("nbor_g.bin", "wb");
    FILE* nbor_b = std::fopen("nbor_b.bin", "wb");

    for(auto&& pattern: result.patterns[0])
        write_pattern(pattern, pat1);
    for(auto&& pattern: result.patterns[1])
        write_pattern(pattern, pat2);

    for(int t : result.indices)
        std::fputc(t, nt);

    for(int t : rn)
        std::fputc(t, nbor_r);
    for(int t : gn)
        std::fputc(t, nbor_g);
    for(int t : bn)
        std::fputc(t, nbor_b);


    //tiles_t zonemap = find_zonemap(zones);

    /*
    for(int y = 0; y != (int)height;  ++y)
    {
        for(int x = 0; x != 32; ++x)
            std::printf("%1x ", r[{x+128,y}]);
        std::printf("\n");
    }
    */
}
