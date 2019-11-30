using ArrayFire
# using Plots
using BenchmarkTools
using Base.Threads
using PyPlot
# using Images
#%%
maxIterations = 2500
gridSize = 2048
# xc = -0.748766710846959 - 2*dx/gridSize*(1500)
# yc = 0.12364084797006399 - 2*dy/gridSize*(200)
# dx = 3.0752019819502152e-9
# dy = 3.0752019819502152e-9
xc=0
yc=0
dx=1
dy=1
xlim = [0.3360220596480308509580, 0.3360220596480365578940]
ylim = [0.0547849977531437254010,  0.0547849977531479950346]
# xlim = [-0.748766713922161, -0.748766707771757]
# ylim = [ 0.123640844894862,  0.123640851045266]
x = range( xlim[1], xlim[2], length = gridSize )
y = range( ylim[1], ylim[2], length = gridSize )

xGrid = [i for i in x, j in y]
yGrid = [j for i in x, j in y]

z0 = xGrid + im*yGrid

function mandelbrotCPU(z0, maxIterations)
    z = copy(z0)
    count = ones( size(z) )

    for n in 1:maxIterations
        z .= z.*z .+ z0
        count .+= abs.( z ).<=2
    end
    count = log.( count )
end

function mandelbrotGPU(z0, maxIterations)
    z = z0
    count = ones(AFArray{Float32}, size(z) )

    for n in 1:maxIterations
        z = z .* z .+ z0
        count = count + (abs(z)<= 4)
    end
    sync(log( count ))
end
#%%
count = mandelbrotGPU(AFArray(z0), maxIterations)
count -= min_all(count)[1]
count /= max_all(count)[1]
img=count
img_local = Array(img)
# heatmap(img)

#%%
# plt.axis("off")
plt.imshow(img_local', cmap="viridis")
plt.savefig("mandel.png", dpi=600)
gcf()

#%%
# warmup

count = mandelbrotCPU(z0, 1)

@btime begin
    count = mandelbrotCPU(z0, maxIterations)

    count .-= minimum(count)
    count ./= maximum(count)
end
# img = AFArray(Array{Float32}(count))

# ArrayFire.image(img)

count = mandelbrotGPU(AFArray(z0), 1)

@btime begin
    count = mandelbrotGPU(AFArray(z0), maxIterations)
    # gpu_time = @elapsed count = mandelbrotGPU(AFArray(z0), maxIterations)

    # ArrayFire.figure(2)
    count -= min_all(count)[1]
    count /= max_all(count)[1]
    img=count
    img_local = Array(img)
end
# img = AFArray{Float32}(count)
# ArrayFire.image(img)


# @show cpu_time, gpu_time, cpu_time/gpu_time
