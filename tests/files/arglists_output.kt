@Module
@InstallIn(SingletonComponent::class)
object AppContextModule {
    @Provides
    @Singleton
    fun provideDataStore(
        @ApplicationContext context: Context,
        param2: String,
        @Inject param3: String,
        param4: DataStore<String>
    ): DataStore<Preferences>
    {

    }
}

