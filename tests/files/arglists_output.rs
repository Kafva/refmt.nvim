impl AppBinding {
    pub fn new(
        name: &str,
        vertex_entry_point: &str,
        fragment_entry_point: &str,
        vertices: Vec<Vertex>,
        config: &wgpu::SurfaceConfiguration,
        device: &wgpu::Device,
        pipeline_layout: &wgpu::PipelineLayout,
        primitive: wgpu::PrimitiveState,
        shader_module: &wgpu::ShaderModule,
    ) -> Self {
    }
}
